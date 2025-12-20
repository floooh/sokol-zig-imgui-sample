const use_docking = @import("build_options").docking;
const ig = if (use_docking) @import("cimgui_docking") else @import("cimgui");
const std = @import("std");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;
const sgimgui = sokol.sgimgui;

const state = struct {
    var pass_action: sg.PassAction = .{};
    var show_first_window: bool = true;
    var show_second_window: bool = true;
};

export fn init() void {
    // initialize sokol-gfx
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    // the debug/tracing ui
    sgimgui.setup(.{});
    // initialize sokol-imgui
    simgui.setup(.{
        .logger = .{ .func = slog.func },
    });
    if (use_docking) {
        ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    // initial clear color
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };
}

export fn frame() void {
    // call simgui.newFrame() before any ImGui calls
    simgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    const backendName: [*c]const u8 = switch (sg.queryBackend()) {
        .D3D11 => "Direct3D11",
        .GLCORE => "OpenGL",
        .GLES3 => "OpenGLES3",
        .METAL_IOS => "Metal iOS",
        .METAL_MACOS => "Metal macOS",
        .METAL_SIMULATOR => "Metal Simulator",
        .WGPU => "WebGPU",
        .VULKAN => "Vulkan",
        .DUMMY => "Dummy",
    };

    var buffer: [128:0]u8 = undefined;

    //=== UI CODE STARTS HERE
    ig.igSetNextWindowPos(.{ .x = 10, .y = 30 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
    if (ig.igBegin("Hello Dear ImGui!", &state.show_first_window, ig.ImGuiWindowFlags_None)) {
        _ = ig.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, ig.ImGuiColorEditFlags_None);

        // Use this with zig 0.16+, which is currently in development
        // _ = std.fmt.bufPrintSentinel(&buffer, "Dear ImGui Version: {s}", .{ig.IMGUI_VERSION}, 0) catch @panic("OOM");

        // Use this with zig 0.15.2, which is currently the stable release
        _ = std.fmt.bufPrintZ(&buffer, "Dear ImGui Version: {s}", .{ig.IMGUI_VERSION}) catch @panic("OOM");

        ig.igTextEx(&buffer);
    }
    ig.igEnd();

    ig.igSetNextWindowPos(.{ .x = 50, .y = 150 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
    if (ig.igBegin("Another Window", &state.show_second_window, ig.ImGuiWindowFlags_None)) {
        // Use this with zig 0.16+, which is currently in development
        // _ = std.fmt.bufPrintSentinel(&buffer, "Sokol Backend: {s}", .{backendName}, 0) catch @panic("OOM");

        // Use this with zig 0.15.2, which is currently the stable release
        _ = std.fmt.bufPrintZ(&buffer, "Sokol Backend: {s}", .{backendName}) catch @panic("OOM");

        ig.igTextEx(&buffer);
    }
    ig.igEnd();

    // the sokol-gfx-imgui debugging ui
    if (ig.igBeginMainMenuBar()) {
        sgimgui.drawMenu("sokol-gfx");
        ig.igEndMainMenuBar();
    }
    sgimgui.draw();
    //=== UI CODE ENDS HERE

    // call simgui.render() inside a sokol-gfx pass
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    simgui.shutdown();
    sgimgui.shutdown();
    sg.shutdown();
}

export fn event(ev: [*c]const sapp.Event) void {
    // forward input events to sokol-imgui
    _ = simgui.handleEvent(ev.*);
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "sokol-zig + Dear Imgui",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
