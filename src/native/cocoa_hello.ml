(** Simple Cocoa FFI example *)

external show_alert : string -> unit = "mlui_show_alert"
(** Show a native macOS alert dialog *)

(** Test function to verify FFI works *)
let test () = show_alert "FFI is working! 🎉"
