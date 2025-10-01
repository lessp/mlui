module Ui = Ui
module Animation = Animation

val run :
  window:Ui.Window.t ->
  ?handle_event:'msg Ui.event_handler ->
  model:'model ->
  update:('msg -> 'model -> 'model) ->
  view:('model -> 'msg Ui.node) ->
  unit ->
  (unit, [ `Msg of string ]) result
