const std = @import("std");

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

    // build the sokol C library with sokol-imgui support
    const dep_sokol = b.dependency("sokol", .{ .imgui = true });

    // inject the cimgui header search path into the sokol C library compile step
    dep_sokol.artifact("sokol").addIncludePath(b.path("cimgui"));

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

    exe.root_module.addImport("sokol", dep_sokol.module("sokol"));
    exe.linkLibrary(lib_cimgui);
    exe.root_module.addIncludePath(b.path("cimgui"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
