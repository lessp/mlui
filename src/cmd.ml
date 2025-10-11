(** Command system for side effects *)

type t = None | ShowWindow | HideWindow | Batch of t list

let none = None
let show_window = ShowWindow
let hide_window = HideWindow

let batch cmds =
  let filtered = List.filter (fun c -> c <> None) cmds in
  match filtered with [] -> None | [ single ] -> single | many -> Batch many
