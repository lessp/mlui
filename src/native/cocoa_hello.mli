(** Simple Cocoa FFI example *)

val show_alert : string -> unit
(** [show_alert message] displays a native macOS alert with the given message *)

val test : unit -> unit
(** [test ()] shows a test alert to verify FFI is working *)
