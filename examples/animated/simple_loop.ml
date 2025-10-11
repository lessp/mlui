open Mlui

type model = { current_time : float }

type msg = Tick of float

let update (Tick delta) model =
  ({ current_time = model.current_time +. delta }, Cmd.none)

let horizontal_slide_animation =
  Animation.(
    animate ~duration:2.0
    |> ease Easing.ease_in_out_cubic
    |> repeat ~mode:Alternate ~duration:2.0
    |> tween ~from:(-200.0) ~to_:200.0 ~interpolate:Interpolate.float)

let view model =
  view
    ~style:
      Style.(
        default
        |> with_background Color.white
        |> with_flex_grow 1.0
        |> with_justify_content Center
        |> with_align_items Center)
    [
      view
        ~style:
          Style.(
            default
            |> with_size ~width:60 ~height:60
            |> with_background Color.black
            |> with_border_radius 16.0
            |> with_transform
                 (TranslateX
                    (Animation.value_at ~time:model.current_time
                       horizontal_slide_animation)))
        [];
    ]

let subscriptions _model = Sub.on_animation_frame (fun delta -> Tick delta)

let run () =
  let window =
    Window.make ~width:600 ~height:400 ~title:"Simple Loop Animation" ()
  in
  (* Start at 1.0 seconds to begin centered in the animation cycle *)
  Mlui.run ~window ~subscriptions ~init:{ current_time = 1.0 } ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
