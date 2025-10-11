open Mlui

module Model = struct
  type t = {
    position : (float * float) Animation.Animated.state;
    current_time : float;
  }

  let init () =
    { position = Animation.Animated.make (400.0, 300.0); current_time = 0.0 }
end

module Msg = struct
  type t = Tick of float | SetPosition of int * int
end

let update (msg : Msg.t) (model : Model.t) : Model.t * Cmd.t =
  match msg with
  | Msg.Tick dt ->
      let new_time = model.current_time +. dt in
      let new_position = Animation.Animated.step new_time model.position in
      ({ position = new_position; current_time = new_time }, Cmd.none)
  | Msg.SetPosition (x, y) ->
      let target = (float_of_int x, float_of_int y) in
      let new_position =
        Animation.Animated.set_target ~duration:0.3
          ~easing:Animation.Easing.ease_out_cubic
          ~interpolate:Animation.Interpolate.position target model.current_time
          model.position
      in
      ({ model with position = new_position }, Cmd.none)

module Styles = struct
  let wrapper =
    Style.(
      default |> with_flex_grow 1.0 |> with_align_items Center
      |> with_justify_content Center)

  let ball =
    Style.(
      default
      |> with_position_type Absolute
      |> with_size ~width:100 ~height:100
      |> with_border_radius 100.0 |> with_background Color.red)
end

let view (model : Model.t) : Msg.t node =
  let x, y = Animation.Animated.value model.position in
  view
    ~on_mouse_move:(fun (x, y) -> Some (Msg.SetPosition (x, y)))
    ~style:Styles.wrapper
    [
      view
        ~style:
          Style.(
            Styles.ball
            |> with_transform (Translate { x = x -. 50.0; y = y -. 50.0 }))
        [];
    ]

let subscriptions _model =
  Sub.batch [ Sub.on_animation_frame (fun dt -> Msg.Tick dt) ]

let run () =
  let window = Window.make ~width:800 ~height:600 ~title:"Ball" () in
  run ~window ~subscriptions ~init:(Model.init ()) ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
