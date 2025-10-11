(* Color, Window, Style, Cmd, Event are now separate modules *)
(* They are not nested under Ui - use them via Mlui *)

(* GADT-based UI system with clear separation *)

type bounds = { x : float; y : float; width : float; height : float }

(* Primitive rendering types - no interaction, just visual *)
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

(* Interactive UI nodes - can have keys, event handlers, bounds *)
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

(* Map messages from one type to another *)
val map_msg : ('a -> 'b) -> 'a node -> 'b node

(* Hit-testing for interactive nodes only *)
type path = int list

type 'msg node_with_bounds = {
  node : 'msg node;
  bounds : bounds;
  children : 'msg node_with_bounds list;
  path : path;
}

(* Interactive UI node constructors *)
val view :
  ?style:Style.t ->
  ?key:string ->
  ?on_click:(unit -> 'msg option) ->
  ?on_mouse_down:(int * int -> 'msg option) ->
  ?on_mouse_up:(int * int -> 'msg option) ->
  ?on_mouse_move:(int * int -> 'msg option) ->
  ?on_mouse_enter:(int * int -> 'msg option) ->
  ?on_mouse_leave:(int * int -> 'msg option) ->
  'msg node list ->
  'msg node
val text :
  ?style:Style.t ->
  ?key:string ->
  ?on_click:(unit -> 'msg option) ->
  string ->
  'msg node
val canvas :
  ?style:Style.t ->
  ?key:string ->
  ?on_click:(unit -> 'msg option) ->
  ?on_mouse_down:(int * int -> 'msg option) ->
  ?on_mouse_up:(int * int -> 'msg option) ->
  ?on_mouse_move:(int * int -> 'msg option) ->
  ?on_mouse_enter:(int * int -> 'msg option) ->
  ?on_mouse_leave:(int * int -> 'msg option) ->
  primitive list ->
  'msg node
val empty : 'msg node

(* Primitive constructors for canvas content *)
val rectangle :
  x:float ->
  y:float ->
  width:float ->
  height:float ->
  style:primitive_style ->
  primitive
val ellipse :
  cx:float ->
  cy:float ->
  rx:float ->
  ry:float ->
  style:primitive_style ->
  primitive
val path : points:(float * float) list -> style:primitive_style -> primitive

(* Primitive style constructors *)
val fill : Color.t -> primitive_style
val stroke : Color.t -> float -> primitive_style
val fill_and_stroke : Color.t -> Color.t -> float -> primitive_style



val run :
  window:Window.t ->
  ?subscriptions:('model -> 'msg Subscription.t) ->
  init:'model ->
  update:('msg -> 'model -> 'model * Cmd.t) ->
  view:('model -> 'msg node) ->
  unit ->
  (unit, [ `Msg of string ]) result
(** Run the UI application.

    Example:
    {[
      let subscriptions model =
        Sub.batch [
          Sub.on_animation_frame (fun dt -> Msg.Tick dt);
          Sub.on_key_down (fun key -> Msg.KeyPressed key);
        ]

      Mlui.run ~window ~subscriptions ~init ~update ~view ()
    ]}
*)

(* MLX/JSX-compatible constructors *)
module Mlx : sig
  (* These functions are designed to work with MLX's JSX syntax transformation.
     They follow the pattern: optional labeled params -> ~children -> unit -> result *)

  (* Wrapper to convert strings into text nodes for JSX *)
  val string : string -> 'msg node

  (* Helper to flatten a list of nodes into a single node (like React.list in Reason) *)
  val list : 'msg node list -> 'msg node

  val view :
    ?style:Style.t ->
    ?key:string ->
    ?on_click:(unit -> 'msg option) ->
    ?on_mouse_down:(int * int -> 'msg option) ->
    ?on_mouse_up:(int * int -> 'msg option) ->
    ?on_mouse_move:(int * int -> 'msg option) ->
    ?on_mouse_enter:(int * int -> 'msg option) ->
    ?on_mouse_leave:(int * int -> 'msg option) ->
    children:'msg node list ->
    unit ->
    'msg node
  [@@JSX]

  val text :
    ?style:Style.t ->
    ?key:string ->
    ?on_click:(unit -> 'msg option) ->
    children:'msg node list ->
    unit ->
    'msg node
  [@@JSX]

  val canvas :
    ?style:Style.t ->
    ?key:string ->
    ?on_click:(unit -> 'msg option) ->
    ?on_mouse_down:(int * int -> 'msg option) ->
    ?on_mouse_up:(int * int -> 'msg option) ->
    ?on_mouse_move:(int * int -> 'msg option) ->
    ?on_mouse_enter:(int * int -> 'msg option) ->
    ?on_mouse_leave:(int * int -> 'msg option) ->
    children:primitive list ->
    unit ->
    'msg node
  [@@JSX]
end
