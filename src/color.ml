type t =
  { r : int
  ; g : int
  ; b : int
  ; a : int
  }

let make ~r ~g ~b ?(a = 255) () = { r; g; b; a }

let red = make ~r:255 ~g:0 ~b:0 ()
let black = make ~r:0 ~g:0 ~b:0 ()
let gray = make ~r:128 ~g:128 ~b:128 ()
let maroon = make ~r:128 ~g:0 ~b:0 ()
let olive = make ~r:128 ~g:128 ~b:0 ()
let green = make ~r:0 ~g:128 ~b:0 ()
let teal = make ~r:0 ~g:128 ~b:128 ()
let navy = make ~r:0 ~g:0 ~b:128 ()
let purple = make ~r:128 ~g:0 ~b:128 ()
let brown = make ~r:165 ~g:42 ~b:42 ()
let dark_green = make ~r:0 ~g:100 ~b:0 ()
let light_blue = make ~r:173 ~g:216 ~b:230 ()
let blue = make ~r:0 ~g:0 ~b:255 ()
let dark_blue = make ~r:0 ~g:0 ~b:139 ()
let saddle_brown = make ~r:139 ~g:69 ~b:19 ()
let white = make ~r:255 ~g:255 ~b:255 ()
let light_gray = make ~r:211 ~g:211 ~b:211 ()
let orange_red = make ~r:255 ~g:69 ~b:0 ()
let yellow = make ~r:255 ~g:255 ~b:0 ()
let lime = make ~r:0 ~g:255 ~b:0 ()
let cyan = make ~r:0 ~g:255 ~b:255 ()
let bright_blue = make ~r:0 ~g:100 ~b:255 ()
let magenta = make ~r:255 ~g:0 ~b:255 ()
let light_yellow = make ~r:255 ~g:255 ~b:224 ()
let light_green = make ~r:144 ~g:238 ~b:144 ()
let light_cyan = make ~r:224 ~g:255 ~b:255 ()
let lavender = make ~r:230 ~g:230 ~b:250 ()
let pink = make ~r:255 ~g:192 ~b:203 ()
let orange = make ~r:255 ~g:165 ~b:0 ()
