# MLui Subscription System

A declarative, type-safe subscription system for handling external events in MLui, inspired by Elm's architecture.

## Overview

Subscriptions provide a declarative way to listen to external event sources (keyboard, mouse, time, etc.) without imperative callbacks. The runtime manages subscription lifecycles automatically based on your model state.

## Quick Start

```ocaml
open Mlui

type model = { count : int }
type msg = Tick of float | KeyPressed of string

let update msg model =
  match msg with
  | Tick dt -> { count = model.count + 1 }
  | KeyPressed key -> 
      Printf.printf "Key: %s\n" key;
      model

let subscriptions model =
  Sub.batch [
    Sub.on_animation_frame (fun dt -> Tick dt);
    Sub.on_key_down (fun key -> KeyPressed key);
  ]

let () =
  let window = Ui.Window.make ~width:400 ~height:300 ~title:"Demo" () in
  Mlui.run ~window ~subscriptions ~model:{count=0} ~update ~view ()
```

## Available Subscriptions

### Time Subscriptions

#### `Sub.on_animation_frame : (float -> 'msg) -> 'msg Sub.t`

Subscribe to animation frames (~60fps). The callback receives delta time in seconds.

**Example:**
```ocaml
let subscriptions model =
  Sub.on_animation_frame (fun delta -> Msg.Tick delta)
```

**Use cases:**
- Animations
- Game loops
- Timers
- FPS counters

---

### Keyboard Subscriptions

#### `Sub.on_key_down : (string -> 'msg) -> 'msg Sub.t`

Subscribe to key press events. The callback receives the key name (e.g., "A", "Space", "Escape").

**Example:**
```ocaml
let subscriptions model =
  Sub.on_key_down (fun key -> Msg.KeyPressed key)
```

#### `Sub.on_key_up : (string -> 'msg) -> 'msg Sub.t`

Subscribe to key release events.

**Example:**
```ocaml
let subscriptions model =
  Sub.on_key_up (fun key -> Msg.KeyReleased key)
```

**Use cases:**
- Keyboard shortcuts
- Game controls
- Text input (when not using UI text fields)
- Hotkeys

---

### Mouse Subscriptions

#### `Sub.on_mouse_down : (int -> int -> 'msg) -> 'msg Sub.t`

Subscribe to mouse button press events. The callback receives x and y coordinates.

**Example:**
```ocaml
let subscriptions model =
  Sub.on_mouse_down (fun x y -> Msg.MousePressed (x, y))
```

#### `Sub.on_mouse_up : (int -> int -> 'msg) -> 'msg Sub.t`

Subscribe to mouse button release events.

**Example:**
```ocaml
let subscriptions model =
  Sub.on_mouse_up (fun x y -> Msg.MouseReleased (x, y))
```

#### `Sub.on_mouse_move : (int -> int -> 'msg) -> 'msg Sub.t`

Subscribe to mouse movement events. **Warning:** This fires very frequently!

**Example:**
```ocaml
let subscriptions model =
  if model.tracking then
    Sub.on_mouse_move (fun x y -> Msg.MouseMoved (x, y))
  else
    Sub.none
```

**Use cases:**
- Drawing applications
- Drag and drop
- Cursor tracking
- Interactive visualizations

---

### Utility Subscriptions

#### `Sub.none : 'msg Sub.t`

No subscription. Use when you conditionally want to stop listening.

**Example:**
```ocaml
let subscriptions model =
  if model.running then
    Sub.on_animation_frame (fun dt -> Msg.Tick dt)
  else
    Sub.none
```

#### `Sub.batch : 'msg Sub.t list -> 'msg Sub.t`

Combine multiple subscriptions.

**Example:**
```ocaml
let subscriptions model =
  Sub.batch [
    Sub.on_animation_frame (fun dt -> Msg.Tick dt);
    Sub.on_key_down (fun key -> Msg.KeyPressed key);
    Sub.on_mouse_move (fun x y -> Msg.MouseMoved (x, y));
  ]
```

---

## Design Patterns

### Conditional Subscriptions

Only subscribe when needed:

```ocaml
let subscriptions model =
  Sub.batch [
    (* Always animate *)
    Sub.on_animation_frame (fun dt -> Msg.Tick dt);
    
    (* Only track mouse when drawing *)
    (if model.is_drawing then
      Sub.on_mouse_move (fun x y -> Msg.MouseMoved (x, y))
     else
      Sub.none);
  ]
```

### State-Based Subscriptions

Change subscriptions based on application state:

```ocaml
type mode = Menu | Playing | Paused

let subscriptions model =
  match model.mode with
  | Menu ->
      Sub.on_key_down (fun key -> 
        if key = "Return" then Msg.StartGame else Msg.NoOp)
  
  | Playing ->
      Sub.batch [
        Sub.on_animation_frame (fun dt -> Msg.GameTick dt);
        Sub.on_key_down (fun key -> Msg.PlayerInput key);
      ]
  
  | Paused ->
      Sub.on_key_down (fun key ->
        if key = "Escape" then Msg.Resume else Msg.NoOp)
```

### Filtering Events

Process only relevant events in your update function:

```ocaml
let update msg model =
  match msg with
  | KeyPressed "Space" -> { model with jumping = true }
  | KeyPressed "Escape" -> { model with paused = not model.paused }
  | KeyPressed _ -> model (* Ignore other keys *)
  | ...
```

---

## How It Works

### Subscription Lifecycle

1. **Declaration**: You declare subscriptions in your `subscriptions` function
2. **Diffing**: Runtime compares new subscriptions to active ones after each update
3. **Management**: Runtime automatically starts/stops subscriptions as needed
4. **Dispatch**: When events occur, runtime calls your subscription callback
5. **Update**: The resulting message flows through your `update` function

### Subscription Diffing

The runtime uses structural equality to detect subscription changes:

```ocaml
(* These are considered equal - no change *)
Sub.on_key_down (fun k -> Msg.Key k)
Sub.on_key_down (fun k -> Msg.Key k)

(* These trigger a re-subscription *)
Sub.on_key_down (fun k -> Msg.Key k)
Sub.on_key_up (fun k -> Msg.Key k)  (* Different variant *)
```

**Performance Note**: Subscriptions are diffed on every model update. Use conditional logic to avoid unnecessary diffing:

```ocaml
(* Good: conditional subscription *)
let subscriptions model =
  if model.needs_animation then
    Sub.on_animation_frame (fun dt -> Tick dt)
  else
    Sub.none

(* Less efficient: always creates subscription *)
let subscriptions model =
  Sub.on_animation_frame (fun dt ->
    if model.needs_animation then Tick dt else NoOp)
```

---

## Migration from `handle_event`

### Old Pattern (Imperative)

```ocaml
let handle_event event =
  match event with
  | Event.KeyUp key -> Some (Msg.KeyPressed key)
  | Event.AnimationFrame dt -> Some (Msg.Tick dt)
  | _ -> None

let () =
  Mlui.run ~window ~handle_event ~model ~update ~view ()
```

### New Pattern (Declarative)

```ocaml
let subscriptions model =
  Sub.batch [
    Sub.on_key_up (fun key -> Msg.KeyPressed key);
    Sub.on_animation_frame (fun dt -> Msg.Tick dt);
  ]

let () =
  Mlui.run ~window ~subscriptions ~model ~update ~view ()
```

### Benefits

- **Declarative**: Subscriptions are data, not callbacks
- **Type-safe**: Compiler ensures message types match
- **State-aware**: Subscriptions can change based on model
- **Composable**: Easy to combine with `Sub.batch`
- **Testable**: Subscription logic is pure functions

---

## Examples

### Timer Application

```ocaml
type model = { elapsed : float }
type msg = Tick of float

let update msg model =
  match msg with
  | Tick dt -> { elapsed = model.elapsed +. dt }

let subscriptions _model =
  Sub.on_animation_frame (fun dt -> Tick dt)
```

See: `examples/subscription_demo/`

### Keyboard Handler

```ocaml
type model = { 
  keys_pressed : string list;
  shift_held : bool;
}

type msg = 
  | KeyDown of string
  | KeyUp of string

let update msg model =
  match msg with
  | KeyDown "Shift" -> { model with shift_held = true }
  | KeyUp "Shift" -> { model with shift_held = false }
  | KeyDown key -> { model with keys_pressed = key :: model.keys_pressed }
  | KeyUp _ -> model

let subscriptions _model =
  Sub.batch [
    Sub.on_key_down (fun key -> KeyDown key);
    Sub.on_key_up (fun key -> KeyUp key);
  ]
```

See: `examples/keyboard_demo/`

### Drawing Application

```ocaml
type model = {
  is_drawing : bool;
  points : (int * int) list;
}

type msg =
  | MouseDown of int * int
  | MouseUp of int * int
  | MouseMove of int * int

let update msg model =
  match msg with
  | MouseDown (x, y) -> 
      { is_drawing = true; points = [(x, y)] }
  
  | MouseMove (x, y) when model.is_drawing ->
      { model with points = (x, y) :: model.points }
  
  | MouseUp _ ->
      { model with is_drawing = false }
  
  | _ -> model

let subscriptions model =
  Sub.batch [
    Sub.on_mouse_down (fun x y -> MouseDown (x, y));
    Sub.on_mouse_up (fun x y -> MouseUp (x, y));
    (* Only track movement while drawing *)
    (if model.is_drawing then
      Sub.on_mouse_move (fun x y -> MouseMove (x, y))
     else
      Sub.none);
  ]
```

See: `examples/mouse_demo/`

---

## Advanced Usage

### Combining Multiple Input Sources

```ocaml
type msg =
  | AnimFrame of float
  | Key of string
  | Click of int * int

let subscriptions model =
  match model.mode with
  | EditMode ->
      Sub.batch [
        Sub.on_animation_frame (fun dt -> AnimFrame dt);
        Sub.on_key_down (fun k -> Key k);
        Sub.on_mouse_down (fun x y -> Click (x, y));
      ]
  
  | ViewMode ->
      Sub.on_key_down (fun k -> Key k)
```

### Performance Optimization

For high-frequency events like `on_mouse_move`, consider:

1. **Throttling in update**: Process every Nth event
2. **Conditional subscriptions**: Only subscribe when needed
3. **Batch processing**: Accumulate events and process in batches

```ocaml
type model = {
  mouse_pos : (int * int) option;
  frame_count : int;
}

let update msg model =
  match msg with
  | MouseMove (x, y) ->
      (* Only update every 5th frame *)
      if model.frame_count mod 5 = 0 then
        { model with mouse_pos = Some (x, y) }
      else
        model
  
  | Tick dt ->
      { model with frame_count = model.frame_count + 1 }
```

---

## Implementation Status

### ✅ Completed (Phase 1-3)

- [x] Core subscription infrastructure
- [x] Runtime integration with diffing
- [x] `Sub.none` and `Sub.batch`
- [x] `Sub.on_animation_frame`
- [x] `Sub.on_key_down` and `Sub.on_key_up`
- [x] `Sub.on_mouse_down`, `Sub.on_mouse_up`, `Sub.on_mouse_move`
- [x] Working demos for all subscription types
- [x] Backward compatibility with `handle_event`

### 🚧 Planned (Phase 4-5)

- [ ] `Sub.Tray.on_click` - System tray subscriptions
- [ ] `Sub.on_quit` - Application quit events
- [ ] Deprecate `handle_event` parameter
- [ ] Optimize subscription diffing with IDs

### 💡 Future Possibilities

- [ ] `Sub.on_timer` - Custom interval timers
- [ ] `Sub.on_window_resize` - Window size changes
- [ ] `Sub.on_window_focus` - Focus/blur events
- [ ] `Sub.every` - Periodic subscriptions
- [ ] WebSocket subscriptions
- [ ] File system watching

---

## FAQ

### Q: Can I use both subscriptions and `handle_event`?

**A:** Yes! They work simultaneously for backward compatibility. However, subscriptions are the recommended approach.

### Q: Do subscriptions work for UI element events (button clicks, etc.)?

**A:** No. UI element events are handled through the element's event handlers (e.g., `~on_click`). Subscriptions are for global/external events.

### Q: Why are my subscriptions not firing?

**A:** Check:
1. Is `~subscriptions` passed to `Mlui.run`?
2. Does your `subscriptions` function return the right subscription for your model state?
3. Is the subscription being conditionally disabled (e.g., returning `Sub.none`)?

### Q: Can I have multiple subscriptions of the same type?

**A:** Yes! Use `Sub.batch` to combine them:

```ocaml
Sub.batch [
  Sub.on_key_down (fun k -> Msg.PlayerOneInput k);
  Sub.on_key_down (fun k -> Msg.PlayerTwoInput k);
]
```

Both will fire for each key event.

### Q: How do I unsubscribe?

**A:** Return `Sub.none` from your `subscriptions` function. The runtime will automatically unsubscribe.

---

## Contributing

The subscription system is under active development. Contributions are welcome!

Areas for improvement:
- Additional subscription types
- Performance optimizations
- Better error messages
- More examples

See `CONTRIBUTING.md` for guidelines.

---

## License

Same as MLui (see main LICENSE file).