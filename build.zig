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

    const dep_cimgui = b.dependency("cimgui", .{});
    const dep_sokol = b.dependency("sokol", .{});

    // need to integrate sokol manually because the sokol C library needs
    // to be built with cimgui support (which means passing a cimgui dependency into the sokol build)
    const mod_sokol = b.addModule("sokol", .{ .root_source_file = dep_sokol.path("src/sokol/sokol.zig") });
    const lib_sokol = try sokol.buildLibSokol(dep_sokol.builder, .{
        .target = target,
        .optimize = optimize,
        .backend = .auto,
        .cimgui = dep_cimgui,
    });
    mod_sokol.linkLibrary(lib_sokol);

    // FIXME: build cimgui library

    exe.root_module.addImport("sokol", mod_sokol);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
