(* Animation - Pure functional time-based animations *)

(* An animation is a function from time to value *)
type 'a t = float -> 'a

(* Repeat mode for looping animations *)
type repeat_mode =
  | Normal (* Restart from beginning each cycle: 0→1, 0→1, 0→1... *)
  | Reverse (* Always play backward: 1→0, 1→0, 1→0... *)
  | Alternate (* Ping-pong forward/backward: 0→1, 1→0, 0→1, 1→0... *)
  | AlternateReverse (* Ping-pong backward/forward: 1→0, 0→1, 1→0, 0→1... *)

(* Create an animation that maps [0, duration] to [0.0, 1.0] *)
let animate ~duration : float t =
 fun time ->
  if time <= 0.0 then
    0.0
  else if time >= duration then
    1.0
  else
    time /. duration

(* Apply an easing function to a normalized animation *)
let ease (easing : float -> float) (anim : float t) : float t =
 fun time ->
  let progress = anim time in
  easing progress

(* Map normalized time [0.0, 1.0] to a range [from, to] using interpolation *)
let tween ~from ~to_ ~interpolate (anim : float t) : 'a t =
 fun time ->
  let progress = anim time in
  interpolate from to_ progress

(* Transform animation output with a function *)
let map (f : 'a -> 'b) (anim : 'a t) : 'b t = fun time -> f (anim time)

(* Create a constant animation (always returns the same value) *)
let const (value : 'a) : 'a t = fun _time -> value

(* Delay the start of an animation *)
let delay (delay_duration : float) (anim : 'a t) : 'a t =
 fun time ->
  if time < delay_duration then
    anim 0.0
  else
    anim (time -. delay_duration)

(* Repeat an animation infinitely *)
let repeat ?(mode = Normal) (anim : 'a t) ~duration : 'a t =
 fun time ->
  if time < 0.0 then
    anim 0.0
  else
    let wrapped = mod_float time duration in
    let cycle = int_of_float (time /. duration) in
    match mode with
    | Normal ->
        anim wrapped
    | Reverse ->
        anim (duration -. wrapped)
    | Alternate ->
        if cycle mod 2 = 0 then
          anim wrapped
        else
          anim (duration -. wrapped)
    | AlternateReverse ->
        if cycle mod 2 = 0 then
          anim (duration -. wrapped)
        else
          anim wrapped

(* Run two animations in sequence *)
let sequence (first : 'a t) (second : 'a t) ~first_duration : 'a t =
 fun time ->
  if time < first_duration then
    first time
  else
    second (time -. first_duration)

(* Run two animations in parallel, returning a tuple *)
let zip (anim_a : 'a t) (anim_b : 'b t) : ('a * 'b) t =
 fun time -> (anim_a time, anim_b time)

(* Evaluate an animation at a specific time *)
let value_at ~time (anim : 'a t) : 'a = anim time

(* Check if animation is complete at given time *)
let is_done ~time ~duration = time >= duration

(* Common interpolation functions *)
module Interpolate = struct
  let float (a : float) (b : float) (t : float) : float = a +. ((b -. a) *. t)

  let int (a : int) (b : int) (t : float) : int =
    let a_f = float_of_int a in
    let b_f = float_of_int b in
    int_of_float (a_f +. ((b_f -. a_f) *. t))

  let position (ax, ay) (bx, by) (t : float) : float * float =
    (float ax bx t, float ay by t)

  let color (a : Color.t) (b : Color.t) (t : float) : Color.t =
    Color.make ~r:(int a.r b.r t) ~g:(int a.g b.g t) ~b:(int a.b b.b t)
      ~a:(int a.a b.a t) ()
end

(* Common easing functions *)
module Easing = struct
  type t = float -> float

  let linear : t = fun t -> t

  let ease_in_quad : t = fun t -> t *. t

  let ease_out_quad : t = fun t -> t *. (2.0 -. t)

  let ease_in_out_quad : t =
   fun t ->
    if t < 0.5 then
      2.0 *. t *. t
    else
      let t' = t -. 0.5 in
      1.0 -. (2.0 *. t' *. t')

  let ease_in_cubic : t = fun t -> t *. t *. t

  let ease_out_cubic : t =
   fun t ->
    let t' = t -. 1.0 in
    (t' *. t' *. t') +. 1.0

  let ease_in_out_cubic : t =
   fun t ->
    if t < 0.5 then
      4.0 *. t *. t *. t
    else
      let f = (2.0 *. t) -. 2.0 in
      1.0 +. (f *. f *. f /. 2.0)

  let ease_out_back : t =
   fun t ->
    let c1 = 1.70158 in
    let c3 = c1 +. 1.0 in
    1.0 +. (c3 *. ((t -. 1.0) ** 3.0)) +. (c1 *. ((t -. 1.0) ** 2.0))

  let ease_in_back : t =
   fun t ->
    let c1 = 1.70158 in
    let c3 = c1 +. 1.0 in
    (c3 *. t *. t *. t) -. (c1 *. t *. t)

  let ease_in_out_back : t =
   fun t ->
    let c1 = 1.70158 in
    let c2 = c1 *. 1.525 in
    if t < 0.5 then
      ((2.0 *. t) ** 2.0) *. (((c2 +. 1.0) *. 2.0 *. t) -. c2) /. 2.0
    else
      let t' = (2.0 *. t) -. 2.0 in
      ((t' *. t' *. (((c2 +. 1.0) *. t') +. c2)) +. 2.0) /. 2.0

  let ease_out_elastic : t =
   fun t ->
    let c4 = 2.0 *. Float.pi /. 3.0 in
    if t = 0.0 then
      0.0
    else if t = 1.0 then
      1.0
    else
      ((2.0 ** (-10.0 *. t)) *. sin (((t *. 10.0) -. 0.75) *. c4)) +. 1.0

  let ease_in_elastic : t =
   fun t ->
    let c4 = 2.0 *. Float.pi /. 3.0 in
    if t = 0.0 then
      0.0
    else if t = 1.0 then
      1.0
    else
      -.(2.0 ** ((10.0 *. t) -. 10.0)) *. sin (((t *. 10.0) -. 10.75) *. c4)

  let ease_in_out_elastic : t =
   fun t ->
    let c5 = 2.0 *. Float.pi /. 4.5 in
    if t = 0.0 then
      0.0
    else if t = 1.0 then
      1.0
    else if t < 0.5 then
      -.((2.0 ** ((20.0 *. t) -. 10.0)) *. sin (((20.0 *. t) -. 11.125) *. c5))
      /. 2.0
    else
      (2.0 ** ((-20.0 *. t) +. 10.0))
      *. sin (((20.0 *. t) -. 11.125) *. c5)
      /. 2.0
      +. 1.0
end

(* Helper for managing animated values with less boilerplate *)
module Animated = struct
  type 'a state = {
    current : 'a;
    target : 'a;
    animation : 'a t option;
    start_time : float;
    duration : float;
  }

  let make initial =
    {
      current = initial;
      target = initial;
      animation = None;
      start_time = 0.0;
      duration = 0.0;
    }

  let set_target ?(duration = 0.3) ?(easing = Easing.ease_out_cubic)
      ~interpolate target current_time state =
    let animation =
      animate ~duration |> ease easing
      |> tween ~from:state.current ~to_:target ~interpolate
    in
    {
      current = state.current;
      target;
      animation = Some animation;
      start_time = current_time;
      duration;
    }

  let step current_time state =
    match state.animation with
    | None ->
        state
    | Some anim ->
        let elapsed = current_time -. state.start_time in
          let value = anim elapsed in
          if elapsed >= state.duration then
            { state with current = state.target; animation = None }
          else
            { state with current = value }

  let value state = state.current
end
