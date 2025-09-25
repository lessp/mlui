type t =
  { foreground : Color.t
  ; background : Color.t
  }

let make ~foreground ~background = { foreground; background }
let default () = make ~foreground:Color.black ~background:Color.white
