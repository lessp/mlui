open Mlui

type ripple = { x : float; y : float; start_time : float }

type model = {
  ball_position : (float * float) Animation.Animated.state;
  current_time : float;
  ripples : ripple list;
}

module Msg = struct
  type t = Tick of float | Click of int * int
end

let update msg model =
  match msg with
  | Msg.Tick dt ->
      let new_time = model.current_time +. dt in
      let new_ball_position =
        Animation.Animated.step new_time model.ball_position
      in

      (* Remove expired ripples (older than 0.8 seconds) *)
      let active_ripples =
        model.ripples |> List.filter @@ fun r -> new_time -. r.start_time < 0.8
      in
      ( {
          ball_position = new_ball_position;
          current_time = new_time;
          ripples = active_ripples;
        },
        Cmd.none )
  | Msg.Click (x, y) ->
      (* Add new ripple *)
      let new_ripple =
        {
          x = float_of_int x;
          y = float_of_int y;
          start_time = model.current_time;
        }
      in
      (* Animate ball to clicked position *)
      let target = (float_of_int x, float_of_int y) in
      let new_ball_position =
        Animation.Animated.set_target ~duration:0.6
          ~easing:Animation.Easing.ease_out_back
          ~interpolate:Animation.Interpolate.position target model.current_time
          model.ball_position
      in
      ( {
          ball_position = new_ball_position;
          current_time = model.current_time;
          ripples = new_ripple :: model.ripples;
        },
        Cmd.none )

let view (model : model) : Msg.t Mlui.node =
  let ball_size = 60 in
  let ball_x, ball_y = Animation.Animated.value model.ball_position in

  view
    ~style:
      Style.(
        default
        |> with_background (Color.make ~r:240 ~g:240 ~b:245 ())
        |> with_flex_grow 1.0)
    ([ (* Render ripples *) ]
    @ (model.ripples
      |> List.map (fun ripple ->
             let elapsed = model.current_time -. ripple.start_time in
             let duration = 0.8 in

             (* Create animations for radius and opacity *)
             let radius_anim =
               Animation.animate ~duration
               |> Animation.ease Animation.Easing.ease_out_quad
               |> Animation.tween ~from:0.0 ~to_:100.0
                    ~interpolate:Animation.Interpolate.float
             in
             let opacity_anim =
               Animation.animate ~duration
               |> Animation.ease Animation.Easing.ease_out_cubic
               |> Animation.tween ~from:255 ~to_:0
                    ~interpolate:Animation.Interpolate.int
             in

             let radius = Animation.value_at ~time:elapsed radius_anim in
             let alpha = Animation.value_at ~time:elapsed opacity_anim in

             (* Ripple using view node with circular border *)
             view
               ~style:
                 Style.(
                   default
                   |> with_position_type Absolute
                   |> with_size
                        ~width:(int_of_float (radius *. 2.0))
                        ~height:(int_of_float (radius *. 2.0))
                   |> with_transform
                        (Translate
                           { x = ripple.x -. radius; y = ripple.y -. radius })
                   |> with_background (Color.make ~r:0 ~g:0 ~b:0 ~a:0 ())
                   |> with_border_radius radius
                   |> with_border
                        ~color:(Color.make ~r:255 ~g:02 ~b:147 ~a:alpha ())
                        ~width:3.0)
               []))
    @ [
        (* The animated ball using position: absolute + transform *)
        view
          ~style:
            Style.(
              default
              |> with_position_type Absolute
              |> with_size ~width:ball_size ~height:ball_size
              |> with_background (Color.make ~r:255 ~g:02 ~b:147 ())
              |> with_border_radius 15.0
              |> with_transform
                   (Translate
                      {
                        x = ball_x -. float_of_int (ball_size / 2);
                        y = ball_y -. float_of_int (ball_size / 2);
                      }))
          [];
      ])

let subscriptions _model =
  Sub.batch
    [
      Sub.on_animation_frame (fun dt -> Msg.Tick dt);
      Sub.on_mouse_down (fun x y -> Msg.Click (x, y));
    ]

let run () =
  let initial_model =
    {
      ball_position = Animation.Animated.make (400.0, 300.0);
      current_time = 0.0;
      ripples = [];
    }
  in

  let window =
    Window.make ~width:800 ~height:600 ~title:"Animation Demo (View Nodes)" ()
  in
  run ~window ~subscriptions ~init:initial_model ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
