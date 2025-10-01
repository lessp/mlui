module Ui = Ui
module Animation = Animation

let run ~window ?handle_event ~model ~update ~view () =
  Ui.run ~window ?handle_event ~model ~update ~view ()
