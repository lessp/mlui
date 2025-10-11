(** Window configuration *)

type t = { width : int; height : int; title : string }

let make ~width ~height ?(title = "Mlui") () = { width; height; title }
