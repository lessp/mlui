open Mlui

type ripple = { x : float; y : float; start_time : float }

type model = {
  ball_x : float;
  ball_y : float;
  position_anim : (float * float) Animation.t option;
  anim_start_time : float;
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

      (* Update ball position from animation if active *)
      (match model.position_anim with
      | Some anim ->
          let elapsed = new_time -. model.anim_start_time in
          let x, y = Animation.value_at ~time:elapsed anim in

          (* Check if animation is done *)
          let new_model =
            if Animation.is_done ~time:elapsed ~duration:0.6 then
              {
                ball_x = x;
                ball_y = y;
                position_anim = None;
                current_time = new_time;
                anim_start_time = model.anim_start_time;
                ripples = model.ripples;
              }
            else
              { model with ball_x = x; ball_y = y; current_time = new_time }
          in

          (* Remove expired ripples (older than 0.8 seconds) *)
          let active_ripples =
            List.filter
              (fun r -> new_time -. r.start_time < 0.8)
              new_model.ripples
          in
          ({ new_model with ripples = active_ripples }, Cmd.none)
      | None ->
          let new_model = { model with current_time = new_time } in
          (* Remove expired ripples *)
          let active_ripples =
            List.filter
              (fun r -> new_time -. r.start_time < 0.8)
              new_model.ripples
          in
          ({ new_model with ripples = active_ripples }, Cmd.none))
  | Msg.Click (x, y) ->
      (* Add new ripple *)
      let new_ripple =
        {
          x = float_of_int x;
          y = float_of_int y;
          start_time = model.current_time;
        }
      in
      (* Create animation: animate over 0.6s, apply easing, tween to target position *)
      (* Create animation *)
      let anim =
        Animation.animate ~duration:0.6
        |> Animation.ease Animation.Easing.ease_out_back
        |> Animation.tween
             ~from:(model.ball_x, model.ball_y)
             ~to_:(float_of_int x, float_of_int y)
             ~interpolate:Animation.Interpolate.position
      in
      ({
        model with
        position_anim = Some anim;
        anim_start_time = model.current_time;
        ripples = new_ripple :: model.ripples;
      }, Cmd.none)

let view (model : model) : Msg.t Mlui.node =
  let ball_size = 60 in

  view
    ~style:
      Style.(default
      |> with_background (Color.make ~r:240 ~g:240 ~b:245 ())
      |> with_flex_grow 1.0)
    ([ (* Render ripples *) ]
    @ List.map
        (fun ripple ->
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

          canvas
            ~style:
              Style.(default
              |> with_position_type Absolute
              |> with_transform (Translate { x = 0.0; y = 0.0 }))
            [
              ellipse ~cx:ripple.x ~cy:ripple.y ~rx:radius ~ry:radius
                ~style:
                  (stroke
                     (Color.make ~r:255 ~g:02 ~b:147 ~a:alpha ())
                     3.0);
            ])
        model.ripples
    @ [
        (* The animated ball using position: absolute + transform *)
        view
          ~style:
            Style.(default
            |> with_position_type Absolute
            |> with_size ~width:ball_size ~height:ball_size
            |> with_background (Color.make ~r:255 ~g:02 ~b:147 ())
            |> with_border_radius 15.0
            |> with_transform
                 (Translate
                    {
                      x = model.ball_x -. float_of_int (ball_size / 2);
                      y = model.ball_y -. float_of_int (ball_size / 2);
                    }))
          [];
      ])

let subscriptions _model =
  Sub.batch [
    Sub.on_animation_frame (fun dt -> Msg.Tick dt);
    Sub.on_mouse_down (fun x y -> Msg.Click (x, y));
  ]

let run () =

  let initial_model =
    {
      ball_x = 400.0;
      ball_y = 300.0;
      position_anim = None;
      anim_start_time = 0.0;
      current_time = 0.0;
      ripples = [];
    }
  in

  let window =
    Window.make ~width:800 ~height:600 ~title:"Animation Demo" ()
  in
  run ~window ~subscriptions ~init:initial_model ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
