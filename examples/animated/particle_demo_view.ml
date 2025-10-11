open Mlui

(* Particle explosion demo showcasing:
   - Particle systems with hundreds of independent animations
   - Simultaneous position, color, and opacity animations
   - Physics-based motion (velocity + gravity)
   - Automatic cleanup of expired particles
*)

type explosion_pattern = Burst | Spiral | Ring

type particle = {
  x : float;
  y : float;
  vx : float; (* velocity x *)
  vy : float; (* velocity y *)
  spawn_time : float;
  hue : float; (* 0.0 to 360.0 for color variation *)
  size_mult : float; (* size variation multiplier *)
}

type model = {
  particles : particle list;
  current_time : float;
  click_count : int;
  current_pattern : explosion_pattern;
  trail_intensity : float; (* 0.0 to 1.0 *)
}

module Msg = struct
  type t =
    | Tick of float
    | Click of int * int
    | SetPattern of explosion_pattern
    | SetTrailIntensity of float
end

(* Create animations for a single particle *)
let make_particle_animations () =
  (* Fade out over lifetime *)
  let opacity_anim =
    Animation.animate ~duration:3.0
    |> Animation.ease Animation.Easing.ease_out_cubic
    |> Animation.tween ~from:255 ~to_:0 ~interpolate:Animation.Interpolate.int
  in

  (* Shrink as it fades *)
  let size_anim =
    Animation.animate ~duration:3.0
    |> Animation.ease Animation.Easing.ease_out_quad
    |> Animation.tween ~from:8.0 ~to_:2.0
         ~interpolate:Animation.Interpolate.float
  in

  (opacity_anim, size_anim)

(* HSL to RGB conversion for rainbow colors *)
let hsl_to_rgb h s l =
  let c = (1.0 -. abs_float ((2.0 *. l) -. 1.0)) *. s in
  let h' = h /. 60.0 in
  let x = c *. (1.0 -. abs_float (mod_float h' 2.0 -. 1.0)) in
  let r1, g1, b1 =
    if h' < 1.0 then
      (c, x, 0.0)
    else if h' < 2.0 then
      (x, c, 0.0)
    else if h' < 3.0 then
      (0.0, c, x)
    else if h' < 4.0 then
      (0.0, x, c)
    else if h' < 5.0 then
      (x, 0.0, c)
    else
      (c, 0.0, x)
  in
  let m = l -. (c /. 2.0) in
  let r = int_of_float ((r1 +. m) *. 255.0) in
  let g = int_of_float ((g1 +. m) *. 255.0) in
  let b = int_of_float ((b1 +. m) *. 255.0) in
  Color.make ~r ~g ~b ()

(* Spawn particles with different patterns *)
let spawn_particles pattern x y current_time =
  let count = 50 in
  List.init count (fun i ->
      let t = float_of_int i /. float_of_int count in
      let angle, speed =
        match pattern with
        | Burst ->
            (* Classic radial burst *)
            let a = (t *. Float.pi *. 2.0) +. Random.float 0.3 in
            let s = 100.0 +. Random.float 150.0 in
            (a, s)
        | Spiral ->
            (* Spiral outward *)
            let a = t *. Float.pi *. 4.0 in
            (* 2 full rotations *)
            let s = 80.0 +. (t *. 180.0) +. Random.float 30.0 in
            (a, s)
        | Ring ->
            (* Outward ring with consistent speed *)
            let a = (t *. Float.pi *. 2.0) +. Random.float 0.2 in
            let s = 150.0 +. Random.float 30.0 in
            (a, s)
      in
      {
        x = float_of_int x;
        y = float_of_int y;
        vx = cos angle *. speed;
        vy = (sin angle *. speed) -. 50.0;
        spawn_time = current_time;
        hue = Random.float 360.0;
        size_mult = 0.8 +. Random.float 0.4;
      })

let update msg model =
  match msg with
  | Msg.Tick dt ->
      let new_time = model.current_time +. dt in

      (* Update particle physics *)
      let gravity = 300.0 in
      let updated_particles =
        model.particles
        |> List.filter_map (fun p ->
               let elapsed = new_time -. p.spawn_time in

               (* Remove particles older than 3.0 seconds *)
               if elapsed > 3.0 then
                 None
               else
                 (* Apply gravity and velocity *)
                 let new_vy = p.vy +. (gravity *. dt) in
                 let new_x = p.x +. (p.vx *. dt) in
                 let new_y = p.y +. (p.vy *. dt) in
                 Some { p with x = new_x; y = new_y; vy = new_vy })
      in

      ( { model with particles = updated_particles; current_time = new_time },
        Cmd.none )
  | Msg.Click (x, y) ->
      (* Coordinates are canvas-relative from on_mouse_down handler *)
      let new_particles =
        spawn_particles model.current_pattern x y model.current_time
      in
      ( {
          model with
          particles = model.particles @ new_particles;
          click_count = model.click_count + 1;
        },
        Cmd.none )
  | Msg.SetPattern pattern ->
      ({ model with current_pattern = pattern }, Cmd.none)
  | Msg.SetTrailIntensity intensity ->
      ({ model with trail_intensity = intensity }, Cmd.none)

(* Render a single particle with trail effect *)
let view_particle ~opacity_anim ~size_anim ~current_time ~trail_intensity p =
  let elapsed = current_time -. p.spawn_time in

  (* Evaluate animations *)
  let alpha = Animation.value_at ~time:elapsed opacity_anim in
  let base_size = Animation.value_at ~time:elapsed size_anim in
  let size = base_size *. p.size_mult in

  (* Vary saturation based on lifetime for fade effect *)
  let saturation = 0.9 -. (elapsed *. 0.2) in
  let color = hsl_to_rgb p.hue saturation 0.6 in

  (* Calculate trail positions (5 trailing positions for subtle motion blur) *)
  let trail_positions = [ 0.2; 0.4; 0.6; 0.8; 1.0 ] in
  let trails =
    trail_positions
    |> List.map (fun trail_factor ->
           let distance_factor = 0.12 *. trail_intensity in
           let trail_x = p.x -. (p.vx *. distance_factor *. trail_factor) in
           let trail_y = p.y -. (p.vy *. distance_factor *. trail_factor) in
           let opacity_factor = 0.6 *. trail_intensity in
           let trail_alpha =
             int_of_float
               (float_of_int alpha *. (1.0 -. trail_factor) *. opacity_factor)
           in
           let trail_size = size *. (1.0 -. (trail_factor *. 0.3)) in

           view
             ~style:
               Style.(
                 default
                 |> with_position_type Absolute
                 |> with_size
                      ~width:(int_of_float (trail_size *. 2.0))
                      ~height:(int_of_float (trail_size *. 2.0))
                 |> with_transform
                      (Translate
                         {
                           x = trail_x -. trail_size;
                           y = trail_y -. trail_size;
                         })
                 |> with_background
                      (Color.make ~r:color.r ~g:color.g ~b:color.b
                         ~a:trail_alpha ())
                 |> with_border_radius trail_size)
             [])
  in

  (* Main particle *)
  let main_particle =
    view
      ~style:
        Style.(
          default
          |> with_position_type Absolute
          |> with_size
               ~width:(int_of_float (size *. 2.0))
               ~height:(int_of_float (size *. 2.0))
          |> with_transform (Translate { x = p.x -. size; y = p.y -. size })
          |> with_background
               (Color.make ~r:color.r ~g:color.g ~b:color.b ~a:alpha ())
          |> with_border_radius size)
      []
  in

  (* Return trails + main particle as a fragment *)
  view ~style:Style.default (trails @ [ main_particle ])

let view (model : model) : Msg.t Mlui.node =
  let opacity_anim, size_anim = make_particle_animations () in

  (* Pattern buttons *)
  let pattern_button pattern label =
    let is_selected = model.current_pattern = pattern in
    view
      ~style:
        Style.(
          default |> with_padding 10
          |> with_background
               (if is_selected then
                  Color.make ~r:100 ~g:100 ~b:200 ()
                else
                  Color.make ~r:60 ~g:60 ~b:80 ())
          |> with_border_radius 5.0)
      ~on_click:(fun () -> Some (Msg.SetPattern pattern))
      [
        text
          ~style:
            Style.(
              default |> with_text_color Color.white |> with_font_size 14.0)
          label;
      ]
  in

  (* Trail intensity slider (simplified - 5 buttons for 0%, 25%, 50%, 75%, 100%) *)
  let trail_button intensity label =
    let is_selected = abs_float (model.trail_intensity -. intensity) < 0.1 in
    view
      ~style:
        Style.(
          default |> with_padding 8
          |> with_background
               (if is_selected then
                  Color.make ~r:100 ~g:200 ~b:100 ()
                else
                  Color.make ~r:60 ~g:80 ~b:60 ())
          |> with_border_radius 3.0)
      ~on_click:(fun () -> Some (Msg.SetTrailIntensity intensity))
      [
        text
          ~style:
            Style.(
              default |> with_text_color Color.white |> with_font_size 12.0)
          label;
      ]
  in

  view
    ~style:
      Style.(
        default
        |> with_background (Color.make ~r:10 ~g:10 ~b:20 ())
        |> with_flex_grow 1.0 |> with_flex_direction Column)
    [
      (* Control panel *)
      view
        ~style:Style.(default |> with_padding 15 |> with_flex_direction Row)
        [
          text
            ~style:
              Style.(
                default
                |> with_text_color Color.white
                |> with_font_size 16.0 |> with_padding 5)
            (Printf.sprintf "Clicks: %d | Particles: %d" model.click_count
               (List.length model.particles));
          view ~style:Style.(default |> with_padding 10) [];
          text
            ~style:
              Style.(
                default
                |> with_text_color Color.white
                |> with_font_size 14.0 |> with_padding 5)
            "Pattern:";
          view
            ~style:Style.(default |> with_flex_direction Row |> with_padding 5)
            [
              pattern_button Burst "Burst";
              view ~style:Style.(default |> with_padding 3) [];
              pattern_button Spiral "Spiral";
              view ~style:Style.(default |> with_padding 3) [];
              pattern_button Ring "Ring";
            ];
          view ~style:Style.(default |> with_padding 10) [];
          text
            ~style:
              Style.(
                default
                |> with_text_color Color.white
                |> with_font_size 14.0 |> with_padding 5)
            "Trails:";
          view
            ~style:Style.(default |> with_flex_direction Row |> with_padding 5)
            [
              trail_button 0.0 "Off";
              view ~style:Style.(default |> with_padding 2) [];
              trail_button 0.25 "25%";
              view ~style:Style.(default |> with_padding 2) [];
              trail_button 0.5 "50%";
              view ~style:Style.(default |> with_padding 2) [];
              trail_button 0.75 "75%";
              view ~style:Style.(default |> with_padding 2) [];
              trail_button 1.0 "100%";
            ];
        ];
      (* Particle canvas *)
      view
        ~style:Style.(default |> with_flex_grow 1.0)
        ~on_mouse_up:(fun (x, y) -> Some (Msg.Click (x, y)))
        (model.particles
        |> List.map
             (view_particle ~opacity_anim ~size_anim
                ~current_time:model.current_time
                ~trail_intensity:model.trail_intensity));
    ]

let subscriptions _model = Sub.on_animation_frame (fun dt -> Msg.Tick dt)

let run () =
  let initial_model =
    {
      particles = [];
      current_time = 0.0;
      click_count = 0;
      current_pattern = Burst;
      trail_intensity = 1.0;
    }
  in

  let window =
    Window.make ~width:1024 ~height:768
      ~title:"Particle Explosion Demo (View Nodes)" ()
  in
  Mlui.run ~window ~subscriptions ~init:initial_model ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
