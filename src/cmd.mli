(** Command system for side effects *)

type t =
  | None
  | ShowWindow
  | HideWindow
  | FocusWindow
  | Batch of t list
      (** Commands that the runtime can execute as side effects.

          Commands are returned from the update function alongside the new
          model, following The Elm Architecture pattern. *)

val none : t
(** No command - used when update has no side effects *)

val show_window : t
(** Command to show the application window *)

val hide_window : t
(** Command to hide the application window *)

val focus_window : t
(** Command to bring the application window to front and focus it *)

val batch : t list -> t
(** Combine multiple commands into one *)
