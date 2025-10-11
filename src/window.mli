(** Window configuration *)

type t = { width : int; height : int; title : string }
(** Window type with dimensions and title *)

val make : width:int -> height:int -> ?title:string -> unit -> t
(** Create a window configuration with specified width, height, and optional title (default: "Mlui") *)
