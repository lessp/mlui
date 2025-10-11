(** Event system for UI interactions *)

type mouse_button = Left | Middle | Right
(** Mouse button types *)

type t =
  | Quit
  | AnimationFrame of float (** delta time in seconds *)
  | MouseDown of { x : int; y : int; button : mouse_button }
  | MouseUp of { x : int; y : int; button : mouse_button }
  | MouseMove of { x : int; y : int }
  | MouseEnter of { x : int; y : int }
  | MouseLeave of { x : int; y : int }
  | KeyUp of string
  | KeyDown of string
(** Event types that can occur in the UI *)
