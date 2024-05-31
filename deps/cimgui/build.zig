const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const cimgui_dep = b.dependency("cimgui", .{});
    const imgui_dep = b.dependency("imgui", .{});

    // create file tree for cimgui and imgui
    const wf = b.addNamedWriteFiles("cimgui");
    _ = wf.addCopyDirectory(cimgui_dep.path(""), "", .{});
    _ = wf.addCopyDirectory(imgui_dep.path(""), "imgui", .{});
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

    // translate-c the cimgui.h file
    const ziphfile = cimgui_dep.path("cimgui.h");
    const translateC = b.addTranslateC(.{
        .root_source_file = ziphfile,
        .target = target,
        .optimize = optimize,
    });
    translateC.defineCMacroRaw("CIMGUI_DEFINE_ENUMS_AND_STRUCTS=\"\"");

    const entrypoint = translateC.getOutput();

    // build cimgui as a module with the header file as the entrypoint
    const mod_cimgui = b.addModule("cimgui", .{
        .root_source_file = entrypoint,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    mod_cimgui.linkLibrary(lib_cimgui);
}
