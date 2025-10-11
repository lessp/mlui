(* External modules are now used: Color, Window, Style, Cmd, Event *)

module Position = struct
  type t = { x : int; y : int }

  let make ~x ~y = { x; y }
end

module RenderStyle = struct
  type t =
    | Fill of Color.t
    | Stroke of Color.t * float
    | FillAndStroke of Color.t * Color.t * float
    | Text of Color.t * string * int * int * float
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

(* Event and Cmd are now external modules *)

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
  | Fragment : { children : 'msg node list } -> 'msg node
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
  | Fragment { children } ->
      Fragment { children = List.map (map_msg f) children }
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

type 'msg event_handler = Ui_event.t -> 'msg option

(* MLX/JSX-compatible constructors *)
module Mlx = struct
  (* Wrapper to convert strings into text nodes for JSX *)
  let string content =
    Text { content; style = Style.default; key = None; on_click = None }

  (* Helper to flatten a list of nodes into a single node (like React.list in Reason) *)
  let list children = Fragment { children }

  (* MLX-compatible view constructor *)
  let view ?(style = Style.default) ?key ?on_click ?on_mouse_down ?on_mouse_up
      ?on_mouse_move ?on_mouse_enter ?on_mouse_leave ~children () =
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
  [@@JSX]

  (* MLX-compatible text constructor *)
  let text ?(style = Style.default) ?key ?on_click ~children () =
    (* Extract text content from children list - expects a single text node *)
    let content =
      match children with
      | [ Text { content; _ } ] ->
          content
      | [] ->
          ""
      | _ ->
          (* For now, concatenate any text nodes found *)
          List.fold_left
            (fun acc node ->
              match node with Text { content; _ } -> acc ^ content | _ -> acc)
            "" children
    in
    Text { content; style; key; on_click }
  [@@JSX]

  (* MLX-compatible canvas constructor *)
  let canvas ?(style = Style.default) ?key ?on_click ?on_mouse_down ?on_mouse_up
      ?on_mouse_move ?on_mouse_enter ?on_mouse_leave ~children () =
    Canvas
      {
        primitives = children;
        style;
        key;
        on_click;
        on_mouse_down;
        on_mouse_up;
        on_mouse_move;
        on_mouse_enter;
        on_mouse_leave;
      }
  [@@JSX]
end
