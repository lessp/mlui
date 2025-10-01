# Mlui Architecture

This document summarises the major pieces that make up the library and how they interact during a frame.

```ocaml
let window = Mlui.Ui.Window.make ~width:800 ~height:600 ~title:"My App" () in
Mlui.run ~window ~model ~update ~view ()
```

The window record (now required, not optional) is the only information the runtime needs to spin up SDL and Wall.

```
+-------------------+        +-------------------+        +-----------------------+
| Declarative Nodes | --(1)->| Flex Layout / Hit | --(2)->| Render Primitives     |
| (Ui.view/canvas)  |        | Testing (ui_layout|        | (render_primitive list)|
+-------------------+        |  + ui_events)     |        +-----------+-----------+
                             +---------+---------+                    |
                                       |                              |
                                       |                      +-------v--------+
                                       |                      | Wall Renderer  |
                                       |                      | (ui_renderer)  |
                                       |                      +-------+--------+
                                       |                              |
                                 +-----v------+                +-------v--------+
                                 | SDL Runtime |<---- events ---| Window System  |
                                 | (ui_runtime)|                +----------------+
                                 +-------------+
```

1. **Declarative tree** — Applications build their UI by composing constructors exposed from `Ui`: `view`, `text`, `canvas`, etc. Each node captures styling, children, and optional event handlers.

2. **Layout and hit-testing** — `Ui_layout` converts nodes into Flexbox nodes, runs the layout engine, and converts the results into `render_primitive` values containing absolute bounds and `RenderStyle.t`. `Ui_events` builds a parallel tree with hit-test metadata (paths, bounds) so pointer events can be mapped back to nodes and handlers.

3. **Rendering** — `Ui_renderer` walks the `render_primitive` list, translating each entry into Wall draw calls. `RenderStyle.t` deliberately mirrors Wall’s paint model (`Fill`, `Stroke`, `FillAndStroke`, `Text`).

4. **Runtime loop** — `Ui_runtime` hosts SDL initialisation and the frame loop. `Mlui.run` (which wraps `Ui.run`) requires a `Ui.Window.t` describing the desired window size. Every frame it:
   - Emits `AnimationFrame` events with delta time for smooth animations
   - Receives SDL events and tries to dispatch them via `Ui_events` first (hover detection, mouse handlers)
   - If no UI handler consumes the event, forwards it to the application-level handler provided to `Mlui.run`
   - Recomputes the layout tree, renders the primitives through Wall, and swaps buffers

5. **Mlui module** — `src/mlui.ml` re-exports `Ui` and `Animation` modules. External code uses `Mlui.Ui.*` and `Mlui.Animation.*`.

6. **Animation system** — `src/animation.ml` provides pure functional time-based animations inspired by Revery. Animations are functions from time to values, composed with `animate`, `ease`, and `tween`.

### Supporting Modules

- `ui_types.ml` — foundational types and helper constructors (`Position`, `Color`, `Style`, `primitive`, `render_primitive`, `RenderStyle`, `transform`).
- `ui_events.ml` — hit-testing utilities (`find_node_at_position`, mouse enter/leave synthesis) shared between SDL runtime and tests.
- `ui_layout.ml` — bridges declarative nodes to the Flex layout engine and back to renderer primitives, including tree-building for hit-testing. Handles `position: absolute` and `transform` application.
- `ui_renderer.ml` — wraps Wall rendering, font management, and FPS overlay when enabled. Renders rounded rectangles via `Wall.Path.round_rect`.
- `ui_runtime.ml` — wraps SDL window lifecycle, event pump, FPS tracking, AnimationFrame event emission, and connects layout + renderer each frame.
- `animation.ml` — pure functional animation system with easing functions, interpolation, and timing combinators.

### Build / Examples Layout

- `examples/simple_canvas/` — minimal non-interactive canvas demo showing how to supply primitives to `Ui.canvas`.
- `examples/simple_draw/` — small TEA-style interactive drawing app driven by `Ui.canvas` mouse events.
- `examples/counter/` — TEA counter app illustrating enter/leave handlers and hover styling.
- `examples/animated/` — animation examples including ball movement with easing and particle explosions.
- `examples/flex_demo/` — demonstrates flexbox layout behavior.
- `examples/paint/` — larger paint program composed of toolbar, palette, and canvas components using `Ui.map_msg`.

These examples serve as reference points when exploring the library.
