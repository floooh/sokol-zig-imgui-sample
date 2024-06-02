const std = @import("std");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const ResolvedTarget = Build.ResolvedTarget;
const Dependency = Build.Dependency;
const sokol = @import("sokol");

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // note that the sokol dependency is built with `.with_imgui_sokol = true`
    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
    });
    const dep_cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });

    // inject the cimgui header search path into the sokol C library compile step
    const cimgui_root = dep_cimgui.namedWriteFiles("cimgui").getDirectory();
    dep_sokol.artifact("sokol_clib").addIncludePath(cimgui_root);

    // from here on different handling for native vs wasm builds
    if (target.result.isWasm()) {
        try buildWasm(b, target, optimize, dep_sokol, dep_cimgui);
    } else {
        try buildNative(b, target, optimize, dep_sokol, dep_cimgui);
    }
}

fn buildNative(b: *Build, target: ResolvedTarget, optimize: OptimizeMode, dep_sokol: *Dependency, dep_cimgui: *Dependency) !void {
    const demo = b.addExecutable(.{
        .name = "demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo.root_module.addImport("sokol", dep_sokol.module("sokol"));
    demo.root_module.addImport("cimgui", dep_cimgui.module("cimgui"));
    b.installArtifact(demo);
    b.step("run", "Run demo").dependOn(&b.addRunArtifact(demo).step);
}

fn buildWasm(b: *Build, target: ResolvedTarget, optimize: OptimizeMode, dep_sokol: *Dependency, dep_cimgui: *Dependency) !void {
    // build the main file into a library, this is because the WASM 'exe'
    // needs to be linked in a separate build step with the Emscripten linker
    const demo = b.addStaticLibrary(.{
        .name = "demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo.root_module.addImport("sokol", dep_sokol.module("sokol"));
    demo.root_module.addImport("cimgui", dep_cimgui.module("cimgui"));

    // get the Emscripten SDK dependency from the sokol dependency
    const dep_emsdk = dep_sokol.builder.dependency("emsdk", .{});

    // need to inject the Emscripten system header include path into
    // the cimgui C library otherwise the C/C++ code won't find
    // C stdlib headers
    const emsdk_incl_path = dep_emsdk.path("upstream/emscripten/cache/sysroot/include");
    dep_cimgui.artifact("cimgui_clib").addSystemIncludePath(emsdk_incl_path);

    // all C libraries need to depend on the sokol library, when building for
    // WASM this makes sure that the Emscripten SDK has been setup before
    // C compilation is attempted (since the sokol C library depends on the
    // Emscripten SDK setup step)
    dep_cimgui.artifact("cimgui_clib").step.dependOn(&dep_sokol.artifact("sokol_clib").step);

    // create a build step which invokes the Emscripten linker
    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = demo,
        .target = target,
        .optimize = optimize,
        .emsdk = dep_emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = false,
        .shell_file_path = dep_sokol.path("src/sokol/web/shell.html").getPath(b),
    });
    // ...and a special run step to start the web build output via 'emrun'
    const run = sokol.emRunStep(b, .{ .name = "demo", .emsdk = dep_emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run demo").dependOn(&run.step);
}
