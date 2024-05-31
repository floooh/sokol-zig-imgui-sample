const std = @import("std");
const sokol = @import("sokol");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const dep_sokol = b.dependency("sokol", .{});

    // need to integrate sokol manually because the sokol C library needs
    // to be built with cimgui support (which means passing a cimgui dependency into the sokol build)
    const mod_sokol = b.addModule("sokol", .{ .root_source_file = dep_sokol.path("src/sokol/sokol.zig") });
    const lib_sokol = try sokol.buildLibSokol(dep_sokol.builder, .{
        .target = target,
        .optimize = optimize,
        .backend = .auto,
        .with_sokol_imgui = true,
    });
    mod_sokol.linkLibrary(lib_sokol);
    lib_sokol.addIncludePath(b.path("cimgui"));

    // build cimgui as C/C++ library
    const lib_cimgui = b.addStaticLibrary(.{
        .name = "cimgui",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_cimgui.linkLibCpp();
    lib_cimgui.addCSourceFiles(.{
        .files = &.{
            "cimgui/cimgui.cpp",
            "cimgui/imgui/imgui.cpp",
            "cimgui/imgui/imgui_widgets.cpp",
            "cimgui/imgui/imgui_draw.cpp",
            "cimgui/imgui/imgui_tables.cpp",
            "cimgui/imgui/imgui_demo.cpp",
        },
    });

    exe.root_module.addImport("sokol", mod_sokol);
    exe.linkLibrary(lib_cimgui);
    exe.root_module.addIncludePath(b.path("cimgui"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
