const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // create file tree for cimgui and imgui
    const wf = b.addNamedWriteFiles("cimgui");
    _ = wf.addCopyDirectory(b.dependency("cimgui", .{}).path(""), "", .{});
    _ = wf.addCopyDirectory(b.dependency("imgui", .{}).path(""), "imgui", .{});
    const root = wf.getDirectory();

    // build cimgui as C/C++ library
    const lib_cimgui = b.addStaticLibrary(.{
        .name = "cimgui",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    lib_cimgui.linkLibCpp();
    lib_cimgui.addCSourceFiles(.{
        .root = root,
        .files = &.{
            b.pathJoin(&.{"cimgui.cpp"}),
            b.pathJoin(&.{ "imgui", "imgui.cpp" }),
            b.pathJoin(&.{ "imgui", "imgui_widgets.cpp" }),
            b.pathJoin(&.{ "imgui", "imgui_draw.cpp" }),
            b.pathJoin(&.{ "imgui", "imgui_tables.cpp" }),
            b.pathJoin(&.{ "imgui", "imgui_demo.cpp" }),
        },
    });
    lib_cimgui.addIncludePath(root);

    // lib compilation depends on file tree
    lib_cimgui.step.dependOn(&wf.step);

    b.installArtifact(lib_cimgui);
}
