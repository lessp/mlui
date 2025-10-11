(** Simple Cocoa FFI example *)

(** Show a native macOS alert dialog *)
external show_alert : string -> unit = "mlui_show_alert"

(** Test function to verify FFI works *)
let test () =
  show_alert "FFI is working! 🎉"
