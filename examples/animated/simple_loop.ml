open Mlui

(* Simplest possible animation example - a box sliding back and forth *)

type model = { current_time : float }

module Msg = struct
  type t = Tick of float
end

(* Create animation that loops forever *)
let position_animation =
  Animation.animate ~duration:2.0
  |> Animation.repeat ~mode:Animation.Alternate ~duration:2.0
  |> Animation.tween ~from:0.0 ~to_:400.0
       ~interpolate:Animation.Interpolate.float

let update (Msg.Tick delta) model =
  ({ current_time = model.current_time +. delta }, Cmd.none)

let view model =
  let x = Animation.value_at ~time:model.current_time position_animation in

  view
    ~style:
      Style.(default
      |> with_background (Color.white)
      |> with_flex_grow 1.0)
    [
      view
        ~style:
          Style.(default
          |> with_position_type Absolute
          |> with_size ~width:60 ~height:60
          |> with_background (Color.black)
          |> with_border_radius 8.0
          |> with_transform (Translate { x; y = 100.0 }))
        [];
    ]

let subscriptions _model =
  Sub.on_animation_frame (fun delta -> Msg.Tick delta)

let run () =
  let window =
    Window.make ~width:600 ~height:400 ~title:"Simple Loop Animation" ()
  in
  Mlui.run ~window ~subscriptions ~init:{ current_time = 0.0 } ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
