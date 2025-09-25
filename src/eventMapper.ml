open Tsdl

let sdl_event_to_msg e =
  match Sdl.Event.(enum (get e typ)) with
  | `Quit -> Some App.Msg.Quit
  | `Mouse_button_down ->
    let x, y = Sdl.Event.((get e mouse_button_x, get e mouse_button_y)) in
    Some (App.Msg.MouseDown (x, y))
  | `Mouse_button_up ->
    let x, y = Sdl.Event.((get e mouse_button_x, get e mouse_button_y)) in
    Some (App.Msg.MouseUp (x, y))
  | `Mouse_motion ->
    let x, y = Sdl.Event.((get e mouse_motion_x, get e mouse_motion_y)) in
    Some (App.Msg.MouseMove (x, y))
  | `Key_down -> None
  | _ -> None
;;
