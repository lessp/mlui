(** Color representation with RGBA components *)

type t = { r : int; g : int; b : int; a : int }
(** Color type with red, green, blue, and alpha channels (0-255) *)

val make : r:int -> g:int -> b:int -> ?a:int -> unit -> t
(** Create a color with specified RGB values and optional alpha (default: 255)
*)

(** {1 Predefined Colors} *)

val transparent : t
val black : t
val white : t
val gray : t
val light_gray : t
val dark_gray : t
val red : t
val green : t
val blue : t
val yellow : t
val cyan : t
val magenta : t
