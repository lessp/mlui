(** Color representation with RGBA components *)

type t = { r : int; g : int; b : int; a : int }

let make ~r ~g ~b ?(a = 255) () = { r; g; b; a }

(* Predefined colors *)
let transparent = make ~r:0 ~g:0 ~b:0 ~a:0 ()
let black = make ~r:0 ~g:0 ~b:0 ()
let white = make ~r:255 ~g:255 ~b:255 ()
let gray = make ~r:128 ~g:128 ~b:128 ()
let light_gray = make ~r:211 ~g:211 ~b:211 ()
let dark_gray = make ~r:64 ~g:64 ~b:64 ()
let red = make ~r:255 ~g:0 ~b:0 ()
let green = make ~r:0 ~g:128 ~b:0 ()
let blue = make ~r:0 ~g:0 ~b:255 ()
let yellow = make ~r:255 ~g:255 ~b:0 ()
let cyan = make ~r:0 ~g:255 ~b:255 ()
let magenta = make ~r:255 ~g:0 ~b:255 ()
