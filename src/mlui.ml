(** MLui - A declarative UI framework for OCaml using The Elm Architecture *)

(* Re-export modules at top level *)
module Style = Style
module Color = Color
module Window = Window
module Cmd = Cmd
module Sub = Subscription
module Tray = Tray
module Animation = Animation
module Cocoa = Cocoa_hello

(* Re-export types *)
type 'msg node = 'msg Ui.node

type primitive_style = Ui.primitive_style =
  | Fill of Color.t
  | Stroke of Color.t * float
  | FillAndStroke of Color.t * Color.t * float

type primitive = Ui.primitive =
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

(* Re-export UI construction functions *)
let view = Ui.view
let text = Ui.text
let canvas = Ui.canvas
let empty = Ui.empty
let map_msg = Ui.map_msg

(* Operator for map_msg - lifting messages *)
let ( <^> ) node f = map_msg f node

(* Re-export primitive constructors *)
let rectangle = Ui.rectangle
let ellipse = Ui.ellipse
let path = Ui.path

(* Re-export primitive styles *)
let fill = Ui.fill
let stroke = Ui.stroke
let fill_and_stroke = Ui.fill_and_stroke

(* Main run function *)
let run ~window ?subscriptions ~init ~update ~view () =
  Ui.run ~window ?subscriptions ~init ~update ~view ()
