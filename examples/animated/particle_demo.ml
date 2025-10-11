open Mlui

(* Particle explosion demo showcasing:
   - Particle systems with hundreds of independent animations
   - Simultaneous position, color, and opacity animations
   - Physics-based motion (velocity + gravity)
   - Automatic cleanup of expired particles
*)

type particle = {
  x : float;
  y : float;
  vx : float; (* velocity x *)
  vy : float; (* velocity y *)
  spawn_time : float;
  hue : float; (* 0.0 to 360.0 for color variation *)
}

type model = {
  particles : particle list;
  current_time : float;
  click_count : int;
}

module Msg = struct
  type t = Tick of float | Click of int * int
end

(* Create animations for a single particle *)
let make_particle_animations () =
  (* Fade out over lifetime *)
  let opacity_anim =
    Animation.animate ~duration:1.5
    |> Animation.ease Animation.Easing.ease_out_cubic
    |> Animation.tween ~from:255 ~to_:0 ~interpolate:Animation.Interpolate.int
  in

  (* Shrink as it fades *)
  let size_anim =
    Animation.animate ~duration:1.5
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
  Ui.Color.make ~r ~g ~b ()

(* Spawn burst of particles at position *)
let spawn_particles x y current_time =
  List.init 50 (fun i ->
      let angle =
        (float_of_int i /. 50.0 *. Float.pi *. 2.0) +. Random.float 0.3
      in
      let speed = 100.0 +. Random.float 150.0 in
      {
        x = float_of_int x;
        y = float_of_int y;
        vx = cos angle *. speed;
        vy = (sin angle *. speed) -. 50.0;
        (* Bias upward *)
        spawn_time = current_time;
        hue = Random.float 360.0;
      })

let update msg model =
  match msg with
  | Msg.Tick dt ->
      let new_time = model.current_time +. dt in

      (* Update particle physics *)
      let gravity = 300.0 in
      let updated_particles =
        List.filter_map
          (fun p ->
            let elapsed = new_time -. p.spawn_time in

            (* Remove particles older than 1.5 seconds *)
            if elapsed > 1.5 then
              None
            else
              (* Apply gravity and velocity *)
              let new_vy = p.vy +. (gravity *. dt) in
              let new_x = p.x +. (p.vx *. dt) in
              let new_y = p.y +. (p.vy *. dt) in
              Some { p with x = new_x; y = new_y; vy = new_vy })
          model.particles
      in

      { model with particles = updated_particles; current_time = new_time }
  | Msg.Click (x, y) ->
      let new_particles = spawn_particles x y model.current_time in
      {
        model with
        particles = model.particles @ new_particles;
        click_count = model.click_count + 1;
      }

let view (model : model) : Msg.t Ui.node =
  let opacity_anim, size_anim = make_particle_animations () in

  Ui.view
    ~style:
      (Ui.Style.default
      |> Ui.Style.with_background (Ui.Color.make ~r:20 ~g:20 ~b:30 ())
      |> Ui.Style.with_flex_grow 1.0
      |> Ui.Style.with_flex_direction Column)
    [
      (* Render all particles *)
      Ui.canvas ~style:Ui.Style.default
        (List.map
           (fun p ->
             let elapsed = model.current_time -. p.spawn_time in

             (* Evaluate animations *)
             let alpha = Animation.value_at ~time:elapsed opacity_anim in
             let size = Animation.value_at ~time:elapsed size_anim in

             (* Create colorful particle with HSL *)
             let color = hsl_to_rgb p.hue 0.8 0.6 in
             let color_with_alpha =
               Ui.Color.make ~r:color.r ~g:color.g ~b:color.b ~a:alpha ()
             in

             (* Draw as small circle *)
             Ui.ellipse ~cx:p.x ~cy:p.y ~rx:size ~ry:size
               ~style:(Ui.fill color_with_alpha))
           model.particles);
    ]

let subscriptions _model =
  Sub.batch [
    Sub.on_animation_frame (fun dt -> Msg.Tick dt);
    Sub.on_mouse_down (fun x y -> Msg.Click (x, y));
  ]

let run () =

  let initial_model = { particles = []; current_time = 0.0; click_count = 0 } in

  let window =
    Ui.Window.make ~width:1024 ~height:768 ~title:"Particle Explosion Demo" ()
  in
  Ui.run ~window ~subscriptions ~init:initial_model ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
