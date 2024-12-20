# sokol-zig-imgui-sample

[![build](https://github.com/floooh/sokol-zig-imgui-sample/actions/workflows/main.yml/badge.svg)](https://github.com/floooh/sokol-zig-imgui-sample/actions/workflows/main.yml)

Sample project for using Dear ImGui with the Sokol Zig bindings.

> NOTE: no longer compatible with Zig 0.13.0, please use the latest Zig nightly

On macOS, Windows and Linux just run:

`zig build run`

To build and run the web version:

`zig build --release=small -Dtarget=wasm32-emscripten run`
