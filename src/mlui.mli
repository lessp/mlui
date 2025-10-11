(** MLui - A declarative UI framework for OCaml using The Elm Architecture *)

(** {1 Core Modules} *)

module Style = Style
module Color = Color
module Window = Window
module Cmd = Cmd
module Sub = Subscription
module Tray = Tray
module Animation = Animation
module Cocoa = Cocoa_hello

(** {1 UI Construction} *)

type 'msg node = 'msg Ui.node

(** {2 Primitive Types} *)

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

(** {2 UI Construction} *)

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

(** {2 Primitive Constructors} *)

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

(** {2 Primitive Styles} *)

val fill : Color.t -> primitive_style
val stroke : Color.t -> float -> primitive_style
val fill_and_stroke : Color.t -> Color.t -> float -> primitive_style

(** {2 Utilities} *)

val map_msg : ('a -> 'b) -> 'a node -> 'b node

(** {2 Operators} *)

val ( <^> ) : 'a node -> ('a -> 'b) -> 'b node
(** [node <^> f] is shorthand for [map_msg f node].

    Example:
    {[
      SubComponent.view model.sub_model
      <^> (fun msg -> Msg.SubMsg msg)
            (* instead of: *)
            SubComponent.view model.sub_model
      |> map_msg (fun msg -> Msg.SubMsg msg)
    ]} *)

(** {1 Application Runtime} *)

val run :
  window:Window.t ->
  ?subscriptions:('model -> 'msg Sub.t) ->
  init:'model ->
  update:('msg -> 'model -> 'model * Cmd.t) ->
  view:('model -> 'msg node) ->
  unit ->
  (unit, [ `Msg of string ]) result
(** Run the UI application.

    Example:
    {[
      open Mlui

      let subscriptions model =
        Sub.batch
          [
            Sub.on_animation_frame (fun dt -> Msg.Tick dt);
            Sub.on_key_down (fun key -> Msg.KeyPressed key);
          ]

      let update msg model =
        match msg with
        | Msg.Tick dt ->
            ({ model with time = model.time +. dt }, Cmd.none)
        | Msg.KeyPressed key ->
            (model, Cmd.none)

      let () =
        let window = Window.make ~width:800 ~height:600 ~title:"My App" () in
        run ~window ~subscriptions ~init:(Model.init ()) ~update ~view ()
    ]} *)
