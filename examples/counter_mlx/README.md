# MLX Integration with MLUI

This example demonstrates how to use MLX (JSX syntax for OCaml) with MLUI's TEA (The Elm Architecture) pattern.

## What is MLX?

MLX is a syntax dialect for OCaml that adds JSX expressions. Instead of writing:

```ocaml
Ui.view ~style:my_style [
  Ui.text ~style:text_style "Hello";
  Ui.view ~style:container_style [
    Ui.text "World"
  ]
]
```

You can write:

```mlx
<view style=my_style>
  <text style=text_style>(string "Hello")</text>
  <view style=container_style>
    <text>(string "World")</text>
  </view>
</view>
```

## Setup

MLX is already configured in this project. The key pieces are:

1. **dune-project** - Defines the MLX dialect and preprocessing
2. **Ui.Mlx module** - Provides JSX-compatible constructors
3. **.mlx files** - Use the `.mlx` extension for files with JSX syntax

## Basic Usage

### 1. Open Ui.Mlx

At the start of your view function, open the Mlx module:

```mlx
let view model =
  let open Ui.Mlx in
  <view style=...>
    ...
  </view>
```

### 2. Use JSX Components

The main components available:
- `<view>` - Container with layout
- `<text>` - Text display
- `<canvas>` - For custom graphics

### 3. Text Content

Wrap text strings with `string`:

```mlx
<text style=my_style>
  (string "Hello, world!")
</text>

<text>
  (string (Printf.sprintf "Count: %d" model.count))
</text>
```

### 4. Dynamic Lists

Use `list` to render dynamic lists of JSX elements:

```mlx
let items =
  List.map (fun item ->
    <view style=item_style>
      <text>(string item.name)</text>
    </view>
  ) model.items
in

<view>
  (list items)
</view>
```

## Creating Custom Components

### Stateless Components

A stateless component is just a function that returns JSX and has the `[@JSX]` attribute:

```mlx
let button ~label ~on_click ~style ~children () =
  let open Ui.Mlx in
  <view style on_click>
    <text>(string label)</text>
    children
  </view>
[@@JSX]

(* Usage *)
let view model =
  let open Ui.Mlx in
  <button
    label="Click me"
    style=my_button_style
    on_click=(fun () -> Some MyMsg)>
    <view />
  </button>
```

**Key points:**
- Function signature: `~props... -> ~children:'msg node list -> unit -> 'msg node`
- Must have `~children` parameter (even if empty)
- Must have trailing `unit` parameter
- Must have `[@@JSX]` attribute

### Stateful TEA Components

For components with their own state, use the TEA pattern:

```mlx
module Counter = struct
  (* 1. Define component's model and messages *)
  type model = { count : int }
  type msg = Increment | Decrement

  (* 2. Initialize and update *)
  let init count = { count }

  let update msg model =
    match msg with
    | Increment -> { count = model.count + 1 }
    | Decrement -> { count = model.count - 1 }

  (* 3. View function takes model and a lift function *)
  let view ~model ~on_msg ~children () =
    let open Ui.Mlx in
    <view style=...>
      <view on_click=(fun () -> Some (on_msg Increment))>
        <text>(string "+")</text>
      </view>
      <text>(string (string_of_int model.count))</text>
      <view on_click=(fun () -> Some (on_msg Decrement))>
        <text>(string "-")</text>
      </view>
      children
    </view>
  [@@JSX]
end

(* Parent component usage *)
type msg =
  | CounterMsg of Counter.msg
  | OtherMsg

type model = {
  counter: Counter.model;
}

let update msg model =
  match msg with
  | CounterMsg counter_msg ->
      { model with counter = Counter.update counter_msg model.counter }
  | OtherMsg -> model

let view model =
  let open Ui.Mlx in
  <view>
    (* Use Counter component, lifting its messages to parent *)
    <Counter.view
      model=model.counter
      on_msg=(fun counter_msg -> CounterMsg counter_msg)>
      <view />
    </Counter.view>
  </view>
```

**The `on_msg` pattern:**
- Child component's view takes `~on_msg` function
- Parent passes a function that wraps child msgs: `on_msg=(fun child_msg -> ParentMsg child_msg)`
- This allows child to send messages that the parent can handle

## Examples

- **main.mlx** - Full counter example with MLX
- **components_example.mlx** - Demonstrates custom stateless and stateful components

## Tips

1. **Self-closing tags** - Use `<view />` for empty children
2. **Expressions** - Wrap OCaml expressions in parentheses: `(my_function arg)`
3. **Lists** - Can't embed `List.map` directly in JSX, create the list first then use `(list items)`
4. **Attributes** - All props use `=` not `:`, e.g., `style=my_style` not `style:my_style`
5. **Open locally** - Use `let open Ui.Mlx in` to avoid `Ui.Mlx.view` everywhere

## Building and Running

```bash
# Build
dune build examples/counter_mlx/main.exe

# Run
dune exec counter_mlx
```

## Resources

- [MLX GitHub](https://github.com/ocaml-mlx/mlx)
- [MLX Documentation](https://github.com/ocaml-mlx/mlx#readme)