> **⚠️ Experimental**: 50% vibes. Use at own risk. Contributions welcome!

# Mlui

A declarative UI framework for OCaml using The Elm Architecture (TEA) pattern, featuring flexbox layout, animations, and functional event handling.

![ml-paint](https://github.com/user-attachments/assets/ddac898d-a54c-4459-965c-2b0485a6c795)

## Getting started

```
git clone https://github.com/lessp/mlui.git
dune pkg lock
dune build
```

Run any example, e.g.

```
./_build/default/examples/paint/main.exe
```


### Prerequisites

#### macOS

```
brew install sdl2
brew install sdl2_ttf
```

## Using the library

```ocaml
open Mlui

module Msg = struct
  type t =
    | Increment
    | Decrement
    | Reset
end

module Model = struct
  type t = {
    counter : int;
  }

  let init () = {
    counter = 0;
  }
end

let update (msg: Msg.t) (model: Model.t): (Model.t * Cmd.t) =
  match msg with
  | Msg.Increment ->
      ({ counter = model.counter + 1 }, Cmd.none)
  | Msg.Decrement ->
      ({ counter = model.counter - 1 }, Cmd.none)
  | Msg.Reset ->
      ({ counter = 0 }, Cmd.none)

module Styles = struct
  let container =
    Style.(
          default
          |> with_flex_grow 1.0
          |> with_flex_direction Column
          |> with_justify_content Center
          |> with_align_items Center)

  let counter =
    Style.(
          default
          |> with_flex_direction Column
          |> with_justify_content Center
          |> with_align_items Center
          |> with_padding 20)

  let text = Style.(
    default
    |> with_font_size 18.0
    |> with_text_color Color.white)

  let button_container =
    Style.(
          default
          |> with_flex_direction Row
          |> with_justify_content Center
          |> with_align_items Center
          |> with_padding 10)

  let button =
    Style.(
          default
          |> with_flex_direction Column
          |> with_justify_content Center
          |> with_align_items Center
          |> with_background Color.blue
          |> with_padding 15
          |> with_size ~width:120 ~height:50)
end

let view (model : Model.t) =
  view
    ~style:Styles.container
    [

      view ~style:Styles.counter [
        text ~style:Styles.text (Printf.sprintf "Count: %d" model.counter);
      ];

      view ~style:Styles.button_container [
        view ~style:Styles.button ~on_click:(fun () -> Some Msg.Increment) [
          text ~style:Styles.text "Increment"
        ];

        view ~style:Styles.button ~on_click:(fun () -> Some Msg.Decrement) [
          text ~style:Styles.text "Decrement"
        ];

        view ~style:Styles.button ~on_click:(fun () -> Some Msg.Reset) [
          text ~style:Styles.text "Reset"
        ]
      ]
    ]

let subscriptions _model = Sub.on_quit Msg.Reset

let run () =
  let window = Window.make ~width:800 ~height:600 ~title:"Counter" () in
  run ~window ~subscriptions ~init:(Model.init ()) ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
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
