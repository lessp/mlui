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
  { current_time = model.current_time +. delta }

let view model =
  let x = Animation.value_at ~time:model.current_time position_animation in

  Ui.view
    ~style:
      (Ui.Style.default
      |> Ui.Style.with_background (Ui.Color.make ~r:240 ~g:240 ~b:245 ())
      |> Ui.Style.with_flex_grow 1.0)
    [
      Ui.view
        ~style:
          (Ui.Style.default
          |> Ui.Style.with_position_type Ui.Absolute
          |> Ui.Style.with_size ~width:60 ~height:60
          |> Ui.Style.with_background (Ui.Color.make ~r:70 ~g:130 ~b:250 ())
          |> Ui.Style.with_border_radius 8.0
          |> Ui.Style.with_transform (Ui.Translate { x; y = 100.0 }))
        [];
    ]

let run () =
  let handle_event = function
    | Ui.Event.AnimationFrame delta ->
        Some (Msg.Tick delta)
    | _ ->
        None
  in

  let window =
    Ui.Window.make ~width:600 ~height:400 ~title:"Simple Loop Animation" ()
  in
  Ui.run ~window ~handle_event ~model:{ current_time = 0.0 } ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
