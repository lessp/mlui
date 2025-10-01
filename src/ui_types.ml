module Position = struct
  type t = { x : int; y : int }

  let make ~x ~y = { x; y }
end

module Window = struct
  type t = { width : int; height : int; title : string }

  let make ~width ~height ?(title = "Mlui") () = { width; height; title }
end

module Color = struct
  type t = { r : int; g : int; b : int; a : int }

  let make ~r ~g ~b ?(a = 255) () = { r; g; b; a }

  let transparent = make ~r:0 ~g:0 ~b:0 ~a:0 ()
  let black = make ~r:0 ~g:0 ~b:0 ()
  let white = make ~r:255 ~g:255 ~b:255 ()
  let gray = make ~r:128 ~g:128 ~b:128 ()
  let light_gray = make ~r:211 ~g:211 ~b:211 ()
  let dark_gray = make ~r:64 ~g:64 ~b:64 ()
  let red = make ~r:255 ~g:0 ~b:0 ()
  let green = make ~r:0 ~g:128 ~b:0 ()
  let blue = make ~r:0 ~g:0 ~b:255 ()
  let yellow = make ~r:255 ~g:255 ~b:0 ()
  let cyan = make ~r:0 ~g:255 ~b:255 ()
  let magenta = make ~r:255 ~g:0 ~b:255 ()
end

module RenderStyle = struct
  type t =
    | Fill of Color.t
    | Stroke of Color.t * float
    | FillAndStroke of Color.t * Color.t * float
    | Text of Color.t * string * int * int * float
end

type flex_direction = Row | Column | RowReverse | ColumnReverse

type justify_content =
  | FlexStart
  | Center
  | FlexEnd
  | SpaceBetween
  | SpaceAround

type align_items = Stretch | Start | Center | End

type position_type = Relative | Absolute

type transform =
  | Translate of { x : float; y : float }
  | Scale of { x : float; y : float }
  | Rotate of float
  | Compose of transform list

module Style = struct
  type t = {
    background_color : Color.t option;
    border_color : Color.t option;
    border_width : float option;
    border_radius : float option;
    text_color : Color.t option;
    font_size : float option;
    padding : int option;
    margin : int option;
    width : int option;
    height : int option;
    position_type : position_type option;
    position_x : int option;
    position_y : int option;
    flex_direction : flex_direction option;
    justify_content : justify_content option;
    align_items : align_items option;
    flex_grow : float option;
    flex_shrink : float option;
    flex_basis : float option;
    transform : transform option;
  }

  let default =
    {
      background_color = None;
      border_color = None;
      border_width = None;
      border_radius = None;
      text_color = None;
      font_size = None;
      padding = None;
      margin = None;
      width = None;
      height = None;
      position_type = None;
      position_x = None;
      position_y = None;
      flex_direction = None;
      justify_content = None;
      align_items = None;
      flex_grow = None;
      flex_shrink = None;
      flex_basis = None;
      transform = None;
    }

  let with_background color style = { style with background_color = Some color }

  let with_border ~color ~width style =
    { style with border_color = Some color; border_width = Some width }

  let with_border_radius radius style =
    { style with border_radius = Some radius }

  let with_text_color color style = { style with text_color = Some color }

  let with_font_size size style = { style with font_size = Some size }

  let with_padding padding style = { style with padding = Some padding }

  let with_size ?width ?height style =
    let style =
      match width with Some w -> { style with width = Some w } | None -> style
    in
    match height with Some h -> { style with height = Some h } | None -> style

  let with_position ~x ~y style =
    { style with position_x = Some x; position_y = Some y }

  let with_flex_direction direction style =
    { style with flex_direction = Some direction }

  let with_justify_content justify style =
    { style with justify_content = Some justify }

  let with_align_items align style = { style with align_items = Some align }

  let with_flex_grow grow style = { style with flex_grow = Some grow }

  let with_flex_shrink shrink style = { style with flex_shrink = Some shrink }

  let with_flex_basis basis style = { style with flex_basis = Some basis }

  let with_transform transform style = { style with transform = Some transform }

  let with_position_type pos_type style =
    { style with position_type = Some pos_type }
end

type bounds = { x : float; y : float; width : float; height : float }

type primitive_style =
  | Fill of Color.t
  | Stroke of Color.t * float
  | FillAndStroke of Color.t * Color.t * float

type primitive =
  | Rectangle of {
      x : float;
      y : float;
      width : float;
      height : float;
      style : primitive_style;
    }
  | Ellipse of {
      cx : float;
      cy : float;
      rx : float;
      ry : float;
      style : primitive_style;
    }
  | Path of { points : (float * float) list; style : primitive_style }

type render_primitive = {
  bounds : bounds;
  shape :
    [ `Rectangle
    | `RoundedRectangle of float
    | `Ellipse
    | `Circle
    | `Path of (float * float) list ];
  style : RenderStyle.t;
}

module Event = struct
  type mouse_button = Left | Middle | Right

  type t =
    | Quit
    | AnimationFrame of float (* delta time in seconds *)
    | MouseDown of { x : int; y : int; button : mouse_button }
    | MouseUp of { x : int; y : int; button : mouse_button }
    | MouseMove of { x : int; y : int }
    | MouseEnter of { x : int; y : int }
    | MouseLeave of { x : int; y : int }
    | KeyUp of string
end

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
    }
      -> 'msg node
  | Text : {
      content : string;
      style : Style.t;
      key : string option;
      on_click : (unit -> 'msg option) option;
    }
      -> 'msg node
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
    }
      -> 'msg node
  | Empty : 'msg node

let rec map_msg f node =
  match node with
  | View
      {
        style;
        children;
        key;
        on_click;
        on_mouse_down;
        on_mouse_up;
        on_mouse_move;
        on_mouse_enter;
        on_mouse_leave;
      } ->
      View
        {
          style;
          children = List.map (map_msg f) children;
          key;
          on_click =
            Option.map (fun handler () -> Option.map f (handler ())) on_click;
          on_mouse_down =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_down;
          on_mouse_up =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_up;
          on_mouse_move =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_move;
          on_mouse_enter =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_enter;
          on_mouse_leave =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_leave;
        }
  | Text { content; style; key; on_click } ->
      Text
        {
          content;
          style;
          key;
          on_click =
            Option.map (fun handler () -> Option.map f (handler ())) on_click;
        }
  | Canvas
      {
        primitives;
        style;
        key;
        on_click;
        on_mouse_down;
        on_mouse_up;
        on_mouse_move;
        on_mouse_enter;
        on_mouse_leave;
      } ->
      Canvas
        {
          primitives;
          style;
          key;
          on_click =
            Option.map (fun handler () -> Option.map f (handler ())) on_click;
          on_mouse_down =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_down;
          on_mouse_up =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_up;
          on_mouse_move =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_move;
          on_mouse_enter =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_enter;
          on_mouse_leave =
            Option.map
              (fun handler pos -> Option.map f (handler pos))
              on_mouse_leave;
        }
  | Empty ->
      Empty

type 'msg interactive_node = 'msg node

type path = int list

type 'msg node_with_bounds = {
  node : 'msg interactive_node;
  bounds : bounds;
  children : 'msg node_with_bounds list;
  path : path;
}

let view ?(style = Style.default) ?key ?on_click ?on_mouse_down ?on_mouse_up
    ?on_mouse_move ?on_mouse_enter ?on_mouse_leave children =
  View
    {
      style;
      children;
      key;
      on_click;
      on_mouse_down;
      on_mouse_up;
      on_mouse_move;
      on_mouse_enter;
      on_mouse_leave;
    }

let text ?(style = Style.default) ?key ?on_click content =
  Text { content; style; key; on_click }

let canvas ?(style = Style.default) ?key ?on_click ?on_mouse_down ?on_mouse_up
    ?on_mouse_move ?on_mouse_enter ?on_mouse_leave primitives =
  Canvas
    {
      primitives;
      style;
      key;
      on_click;
      on_mouse_down;
      on_mouse_up;
      on_mouse_move;
      on_mouse_enter;
      on_mouse_leave;
    }

let empty = Empty

let rectangle ~x ~y ~width ~height ~style =
  Rectangle { x; y; width; height; style }

let ellipse ~cx ~cy ~rx ~ry ~style = Ellipse { cx; cy; rx; ry; style }

let path ~points ~style = Path { points; style }

let fill color = Fill color

let stroke color width = Stroke (color, width)

let fill_and_stroke fill_color stroke_color width =
  FillAndStroke (fill_color, stroke_color, width)

type 'msg event_handler = Event.t -> 'msg option
