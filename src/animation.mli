(* Animation - Pure functional time-based animations
 *
 * Animations are represented as functions from time (in seconds) to values.
 * This allows for composable, declarative animation definitions.
 *
 * Example usage:
 *   let position_anim =
 *     Animation.animate ~duration:1.0
 *     |> Animation.ease Easing.ease_out_back
 *     |> Animation.tween
 *          ~from:(0.0, 0.0)
 *          ~to_:(100.0, 200.0)
 *          ~interpolate:Interpolate.position
 *   in
 *   let (x, y) = Animation.value_at ~time:0.5 position_anim
 *)

type 'a t
(** An animation that produces values of type 'a *)

(** {1 Creating Animations} *)

val animate : duration:float -> float t
(** [animate ~duration] creates an animation that maps the time range
    [0, duration] to the normalized range [0.0, 1.0]. *)

val const : 'a -> 'a t
(** [const value] creates an animation that always returns [value] regardless of
    time. *)

(** {1 Transforming Animations} *)

val ease : (float -> float) -> float t -> float t
(** [ease easing anim] applies an easing function to a normalized animation (0.0
    to 1.0). The easing function should map [0.0, 1.0] to [0.0, 1.0] with custom
    acceleration. *)

val tween :
  from:'a -> to_:'a -> interpolate:('a -> 'a -> float -> 'a) -> float t -> 'a t
(** [tween ~from ~to_ ~interpolate anim] maps a normalized animation to a range
    of values. The interpolate function defines how to blend between [from] and
    [to_] given a progress value. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** [map f anim] transforms the output of an animation using function [f]. *)

(** {1 Timing Combinators} *)

val delay : float -> 'a t -> 'a t
(** [delay duration anim] delays the start of an animation by [duration]
    seconds. During the delay, the animation will return its value at time 0. *)

val repeat : 'a t -> duration:float -> 'a t
(** [repeat anim ~duration] repeats an animation infinitely. The animation will
    loop every [duration] seconds. *)

val sequence : 'a t -> 'a t -> first_duration:float -> 'a t
(** [sequence first second ~first_duration] runs [first] then [second] in
    sequence. [first] runs for [first_duration] seconds, then [second] starts.
*)

val zip : 'a t -> 'b t -> ('a * 'b) t
(** [zip anim_a anim_b] runs two animations in parallel, returning their values
    as a tuple. *)

(** {1 Evaluating Animations} *)

val value_at : time:float -> 'a t -> 'a
(** [value_at ~time anim] evaluates the animation at the given time (in
    seconds). *)

val is_done : time:float -> duration:float -> bool
(** [is_done ~time ~duration] checks if an animation is complete at the given
    time. *)

(** {1 Interpolation Functions} *)

module Interpolate : sig
  val float : float -> float -> float -> float
  (** Linear interpolation between two floats *)

  val int : int -> int -> float -> int
  (** Linear interpolation between two integers *)

  val position : float * float -> float * float -> float -> float * float
  (** Linear interpolation between two positions (x, y) *)

  val color : Color.t -> Color.t -> float -> Color.t
  (** Linear interpolation between two colors *)
end

(** {1 Easing Functions}

    Easing functions map normalized time [0.0, 1.0] to [0.0, 1.0] with custom
    acceleration curves. All easing functions should:
    - Return 0.0 when given 0.0
    - Return 1.0 when given 1.0
    - Be continuous in the interval [0.0, 1.0] *)
module Easing : sig
  type t = float -> float

  val linear : t
  (** No easing - constant velocity *)

  val ease_in_quad : t
  (** Quadratic easing functions *)

  val ease_out_quad : t
  val ease_in_out_quad : t

  val ease_in_cubic : t
  (** Cubic easing functions *)

  val ease_out_cubic : t
  val ease_in_out_cubic : t

  val ease_in_back : t
  (** Back easing functions - slight overshoot/undershoot *)

  val ease_out_back : t
  val ease_in_out_back : t

  val ease_in_elastic : t
  (** Elastic easing functions - bouncy effect *)

  val ease_out_elastic : t
  val ease_in_out_elastic : t
end
