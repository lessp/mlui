module Position : sig
  type t = { x : int; y : int }
  val make : x:int -> y:int -> t
end

module Window : sig
  type t = { width : int; height : int; title : string }
  val make : width:int -> height:int -> ?title:string -> unit -> t
end

module Color : sig
  type t = { r : int; g : int; b : int; a : int }

  val make : r:int -> g:int -> b:int -> ?a:int -> unit -> t

  val transparent : t
  val black : t
  val white : t
  val gray : t
  val light_gray : t
  val dark_gray : t
  val red : t
  val green : t
  val blue : t
  val yellow : t
  val cyan : t
  val magenta : t
end

(* Flexbox layout types *)
type flex_direction = Row | Column | RowReverse | ColumnReverse
type justify_content =
  | FlexStart
  | Center
  | FlexEnd
  | SpaceBetween
  | SpaceAround
type align_items = Stretch | Start | Center | End

(* Position types *)
type position_type = Relative | Absolute

(* Transform types *)
type transform =
  | Translate of { x : float; y : float }
  | Scale of { x : float; y : float }
  | Rotate of float
  | Compose of transform list

(* New component-oriented Style system *)
module Style : sig
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
    (* Flexbox properties *)
    flex_direction : flex_direction option;
    justify_content : justify_content option;
    align_items : align_items option;
    flex_grow : float option;
    flex_shrink : float option;
    flex_basis : float option;
    transform : transform option;
  }

  val default : t

  val with_background : Color.t -> t -> t
  val with_border : color:Color.t -> width:float -> t -> t
  val with_border_radius : float -> t -> t
  val with_text_color : Color.t -> t -> t
  val with_font_size : float -> t -> t
  val with_padding : int -> t -> t
  val with_size : ?width:int -> ?height:int -> t -> t
  val with_position : x:int -> y:int -> t -> t
  val with_flex_direction : flex_direction -> t -> t
  val with_justify_content : justify_content -> t -> t
  val with_align_items : align_items -> t -> t
  val with_flex_grow : float -> t -> t
  val with_flex_shrink : float -> t -> t
  val with_flex_basis : float -> t -> t
  val with_position_type : position_type -> t -> t
  val with_transform : transform -> t -> t
end

type bounds = { x : float; y : float; width : float; height : float }

(* Event types *)
module Event : sig
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

(* GADT-based UI system with clear separation *)

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

type 'msg event_handler = Event.t -> 'msg option

val run :
  window:Window.t ->
  ?handle_event:'msg event_handler ->
  model:'model ->
  update:('msg -> 'model -> 'model) ->
  view:('model -> 'msg node) ->
  unit ->
  (unit, [ `Msg of string ]) result

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
