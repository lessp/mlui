open Mlui

(* Simplest possible animation example - a box sliding back and forth *)

type model = { current_time : float }

module Msg = struct
  type t = Tick of float
end

(* Create animation that loops forever *)
let position_animation =
  Animation.animate ~duration:2.0
  |> Animation.repeat ~duration:2.0
  |> Animation.tween ~from:0.0 ~to_:400.0
       ~interpolate:Animation.Interpolate.float

let update (Msg.Tick delta) model =
  ({ current_time = model.current_time +. delta }, Cmd.none)

let view model =
  let x = Animation.value_at ~time:model.current_time position_animation in

  Ui.view
    ~style:
      (Style.default
      |> Style.with_background (Color.make ~r:240 ~g:240 ~b:245 ())
      |> Style.with_flex_grow 1.0)
    [
      Ui.view
        ~style:
          (Style.default
          |> Style.with_position_type Style.Absolute
          |> Style.with_size ~width:60 ~height:60
          |> Style.with_background (Color.make ~r:70 ~g:130 ~b:250 ())
          |> Style.with_border_radius 8.0
          |> Style.with_transform (Style.Translate { x; y = 100.0 }))
        [];
    ]

let subscriptions _model =
  Sub.on_animation_frame (fun delta -> Msg.Tick delta)

let run () =
  let window =
    Window.make ~width:600 ~height:400 ~title:"Simple Loop Animation" ()
  in
  Ui.run ~window ~subscriptions ~init:{ current_time = 0.0 } ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
