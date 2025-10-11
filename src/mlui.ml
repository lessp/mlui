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

(* Re-export UI construction functions *)
let view = Ui.view
let text = Ui.text
let map_msg = Ui.map_msg

(* Main run function *)
let run ~window ?subscriptions ~init ~update ~view () =
  Ui.run ~window ?subscriptions ~init ~update ~view ()
