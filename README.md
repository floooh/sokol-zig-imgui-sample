# sokol-zig-imgui-sample

[![build](https://github.com/floooh/sokol-zig-imgui-sample/actions/workflows/main.yml/badge.svg)](https://github.com/floooh/sokol-zig-imgui-sample/actions/workflows/main.yml)

Sample project for using Dear ImGui with the Sokol Zig bindings.

> [!NOTE]
> requires zig 0.17.0-dev (as of 0.17.0-dev.1737+de207594e)

On macOS, Windows and Linux just run:

`zig build run`

To build and run the web version:

First install a local Emscripten SDK into `./zig-pkg/`:

`zig build install-emsdk`

Then build and run for target `wasm32-emscripten`:

`zig build --release=small -Dtarget=wasm32-emscripten run`

...or for the Dear ImGui docking branch:

`zig build -Ddocking run`

`zig build --release=small -Ddocking -Dtarget=wasm32-emscripten run`
