> Functional _but_ contains 50% vibes.

# Mlui

A basic UI framework for OCaml using The Elm Architecture (TEA) pattern.

## Getting started

```
git clone https://github.com/lessp/mlui.git
dune pkg lock
dune build
```

Run any example, e.g.

```
_build/default/examples/paint/main.xe
```


### macOS

```
brew install sdl2
brew install sdl2_ttf
```

## Examples

### Paint (`examples/paint/`)

Full-featured painting application with:
- Multiple drawing tools (pencil, brush, shapes, eraser)
- Color palette with foreground/background colors
- Tool variants (fill styles, thicknesses)
- Canvas with immediate visual feedback

Run with:
```bash
dune exec paint
```

### Simple Draw (`examples/simple_draw/`)

Minimalist drawing application demonstrating:
- Canvas event handlers
- Path drawing with mouse/pointer events
- Color and size selection
- Clear functionality

Run with:
```bash
dune exec simple-draw
```

### Flex Demo (`examples/flex_demo/`)

Shows basic Flexbox layout behaviour.

```bash
dune exec flex_demo
```

### Counter (`examples/counter/`)

Simple counter demonstrating The Elm Architecture:
- Button click handlers
- State management
- Message-based updates
- Dynamic styling

Run with:
```bash
dune exec counter
```

## Using the Library

```ocaml
open Mlui

module Msg = struct
  type t = Click | Hover of int * int
end

let view model =
  Ui.view ~on_click:(fun () -> Some Msg.Click) [
    Ui.text "Click me!"
  ]

let update msg model =
  match msg with
  | Msg.Click -> { model with clicked = true }
  | Msg.Hover (x, y) -> { model with position = (x, y) }

let window = Ui.Window.make ~width:800 ~height:600

let () =
  match Ui.run ~window ~model ~update ~view () with
  | Ok () -> ()
  | Error (`Msg err) -> Printf.eprintf "Error: %s\n" err
```

## Animation

Pure functional animations inspired by [Revery](https://github.com/revery-ui/revery). Animations are **functions from time to values** - composable, type-safe, and stateless.

### Quick Example

```ocaml
(* Create animation: 600ms from (0,0) to (100,200) with easing *)
let animation =
  Animation.animate ~duration:0.6
  |> Animation.ease Easing.ease_out_back
  |> Animation.tween ~from:(0.0, 0.0) ~to_:(100.0, 200.0)
       ~interpolate:Interpolate.position

(* Evaluate at any time *)
let (x, y) = Animation.value_at ~time:elapsed animation
```

### How It Works

```ocaml
(* Store time in model *)
type model = { current_time : float }

(* Handle AnimationFrame events (~16ms at 60fps) *)
let handle_event = function
  | Ui.Event.AnimationFrame delta -> Some (Tick delta)
  | _ -> None

(* Update time each frame *)
let update (Tick delta) model =
  { current_time = model.current_time +. delta }

(* Create animation that loops *)
let position_animation =
  Animation.animate ~duration:2.0
  |> Animation.repeat ~duration:2.0
  |> Animation.tween ~from:0.0 ~to_:100.0
       ~interpolate:Interpolate.float

(* Use in view *)
let view model =
  let x = Animation.value_at ~time:model.current_time position_animation in
  Ui.view
    ~style:(Ui.Style.default
            |> Ui.Style.with_position_type Ui.Absolute
            |> Ui.Style.with_transform (Ui.Translate { x; y = 50.0 }))
    []
```

## Component Composition

Use `Ui.map_msg` to compose components with different message types:

```ocaml
(* Toolbar with its own message type *)
let toolbar_view model =
  Toolbar.view model.toolbar
  |> Ui.map_msg (fun msg -> ToolbarMsg msg)

(* Color palette with its message type *)
let palette_view model =
  ColorPalette.view model.palette
  |> Ui.map_msg (fun msg -> PaletteMsg msg)
```

## License

MIT
