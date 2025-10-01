# TEA-Style Event Handlers in Mlui

## Overview

Mlui supports The Elm Architecture (TEA) style event handlers on UI elements. This provides a declarative way to handle user interactions without manual hit-testing.

## Key Changes

### 1. Message-Parameterized UI Nodes

UI nodes are now parameterized by a message type:

```ocaml
type 'msg node =
  | View : {
      style : Style.t;
      children : 'msg node list;
      key : string option;
      on_click : (unit -> 'msg option) option;
      on_mouse_down : (int * int -> 'msg option) option;
      on_mouse_up : (int * int -> 'msg option) option;
      on_mouse_move : (int * int -> 'msg option) option;
      on_mouse_enter : (int * int -> 'msg option) option;
      on_mouse_leave : (int * int -> 'msg option) option;
    } -> 'msg node
  | Text : {
      content : string;
      style : Style.t;
      key : string option;
      on_click : (unit -> 'msg option) option;
    } -> 'msg node
  | Canvas : {
      primitives : primitive list;
      style : Style.t;
      key : string option;
      on_click : (unit -> 'msg option) option;
      on_mouse_down : (int * int -> 'msg option) option;
      on_mouse_up : (int * int -> 'msg option) option;
      on_mouse_move : (int * int -> 'msg option) option;
      on_mouse_enter : (int * int -> 'msg option) option;
      on_mouse_leave : (int * int -> 'msg option) option;
    } -> 'msg node
  | Empty : 'msg node
```

### 2. Event Handlers

Event handlers are optional functions that return `'msg option`:
- `on_click: (unit -> 'msg option) option` - Triggered on left mouse button click
- `on_mouse_down: (int * int -> 'msg option) option` - Triggered on any mouse button down
- `on_mouse_up: (int * int -> 'msg option) option` - Triggered on any mouse button up
- `on_mouse_move: (int * int -> 'msg option) option` - Triggered on mouse movement
- `on_mouse_enter: (int * int -> 'msg option) option` - Triggered when cursor enters the element bounds
- `on_mouse_leave: (int * int -> 'msg option) option` - Triggered when cursor exits the element bounds

### 3. Message Mapping

When composing components with different message types, use `Ui.map_msg`:

```ocaml
val map_msg : ('a -> 'b) -> 'a node -> 'b node
```

## Usage Examples

### Basic Button with Click Handler

```ocaml
open Mlui

let button_view () =
  let style =
    Ui.Style.default
    |> Ui.Style.with_size ~width:100 ~height:40
    |> Ui.Style.with_background Ui.Color.blue
    |> Ui.Style.with_border_radius 8.0
  in
  Ui.view ~style ~on_click:(fun () -> Some ButtonClicked)
    [ Ui.text "Click me" ]
```

### Color Palette Example

```ocaml
open Mlui

module Msg = struct
  type t =
    | SelectColor of Ui.Color.t
    | SwapColors
end

let color_button color =
  let style =
    Ui.Style.default
    |> Ui.Style.with_background color
    |> Ui.Style.with_size ~width:20 ~height:20
    |> Ui.Style.with_border_radius 4.0
  in
  Ui.view ~style ~on_click:(fun () -> Some (Msg.SelectColor color)) []

let swap_button =
  Ui.view 
    ~style:swap_style 
    ~on_click:(fun () -> Some Msg.SwapColors)
    [Ui.text "Swap"]
```

### Canvas with Mouse Tracking

```ocaml
open Mlui

let drawing_canvas =
  Ui.canvas
    ~style:canvas_style
    ~on_mouse_down:(fun (x, y) -> Some (StartDrawing (x, y)))
    ~on_mouse_move:(fun (x, y) -> Some (ContinueDrawing (x, y)))
    ~on_mouse_up:(fun (x, y) -> Some (EndDrawing (x, y)))
    primitives
```

`primitives` is a list built with helpers such as `Ui.rectangle`, `Ui.ellipse`, or `Ui.path`. Canvas event callbacks receive coordinates relative to the canvas’ own origin after layout, so no manual offset is needed.

## Component Composition

### Mapping Sub-component Messages

When using sub-components with their own message types:

```ocaml
open Mlui

(* In App.ml *)
module Msg = struct
  type t =
    | ToolbarMsg of Toolbar.Msg.t
    | ColorPaletteMsg of ColorPalette.Msg.t
    | CanvasMsg of Canvas.Msg.t
end

let view model =
  let toolbar_view = 
    Toolbar.view model.toolbar
    |> Ui.map_msg (fun msg -> Msg.ToolbarMsg msg)
  in
  
  let color_palette_view =
    ColorPalette.view model.color_palette
    |> Ui.map_msg (fun msg -> Msg.ColorPaletteMsg msg)
  in
  
  Ui.view ~style:app_style [
    toolbar_view;
    color_palette_view;
  ]
```

## Migration Guide

### Before (Manual Hit-Testing)

```ocaml
let get_color_at_position model pos =
  let rec loop colors index =
    match colors with
    | [] -> None
    | color :: rest ->
        let color_position = get_color_position model index in
        let in_bounds =
          pos.x >= color_position.x && 
          pos.x < color_position.x + size &&
          pos.y >= color_position.y && 
          pos.y < color_position.y + size
        in
        if in_bounds then Some color
        else loop rest (index + 1)
  in
  loop available_colors 0

(* In update function *)
let update msg model =
  match msg with
  | MouseDown (x, y) ->
      let pos = Position.make ~x ~y in
      match get_color_at_position model pos with
      | Some color -> { model with selected_color = color }
      | None -> model
```

### After (Declarative Event Handlers)

```ocaml
let color_button color =
  Ui.view 
    ~style:color_style
    ~on_click:(fun () -> Some (SelectColor color))
    []

let view model =
  let color_buttons = 
    List.map color_button available_colors
  in
  Ui.view ~style:palette_style color_buttons

(* In update function - much simpler *)
let update msg model =
  match msg with
  | SelectColor color -> 
      { model with selected_color = color }
```

## Implementation Details

### Hit-Testing

The UI system automatically performs hit-testing using the computed layout bounds. When an event occurs:

1. The system traverses the node tree with bounds
2. Finds the topmost node at the event position
3. Checks if the node has a handler for the event type
4. If found, calls the handler and returns the message
5. The message is passed to the application's update function

### Event Priority

- UI node event handlers have priority over app-level event handlers
- Children are checked before parents (front-to-back)
- Only the topmost matching node's handler is called

## Benefits

1. **Declarative**: Define behavior where you define appearance
2. **Type-Safe**: Messages are strongly typed
3. **Composable**: Easy to compose components with message mapping
4. **No Manual Hit-Testing**: The framework handles all hit-testing
5. **Cleaner Code**: Separation of concerns between view and update logic

## New Features

### Position: Absolute

Elements can be removed from flex flow and positioned absolutely:

```ocaml
open Mlui

Ui.view
  ~style:(Ui.Style.default
          |> Ui.Style.with_position_type Ui.Absolute
          |> Ui.Style.with_size ~width:100 ~height:100
          |> Ui.Style.with_transform (Ui.Translate { x = 50.0; y = 100.0 }))
  []
```

### Transform

Apply visual transformations after layout:

```ocaml
open Mlui

Ui.Style.with_transform (Ui.Translate { x = 10.0; y = 20.0 })
(* Future: Scale and Rotate *)
```

### Border Radius

Rounded corners on views and canvases:

```ocaml
open Mlui

Ui.Style.with_border_radius 15.0  (* Creates rounded corners *)
```

Note: radius should be less than half the element size for proper rendering.

## Complete Examples

See the following examples for complete working demonstrations:
- `examples/counter/` - Button click handlers, color selection, counter increment/decrement
- `examples/animated/ball_demo.ml` - Click-to-move animation with position: absolute and transform
- `examples/animated/particle_demo.ml` - Particle system with hundreds of simultaneous animations
