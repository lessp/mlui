(** System tray icon support for mlui

    Currently supports macOS only. Other platforms will compile but operations
    will be no-ops. *)

type t
(** An opaque handle to a system tray item *)

val make : ?image_path:string -> unit -> t
(** [make ?image_path ()] creates a new system tray item.

    @param image_path
      Optional absolute path to an image file. Use relative paths from your
      assets directory.
    @return A new tray handle

    The tray item is automatically cleaned up when garbage collected.

    Examples:
    {[
      (* Image-based tray icon *)
      let tray = Tray.make ~image_path:"/absolute/path/to/icon.png" ()

      (* Text-only tray item (will be set later with set_title) *)
      let tray = Tray.make ()
    ]} *)

val set_title : t -> text:string -> t
(** [set_title tray ~text] sets the tray item to display text.

    Note: This will clear any image previously set. Returns the tray handle for
    chaining.

    Examples:
    {[
      let tray = Tray.make () |> Tray.set_title ~text:"My App"

      (* Can also be used imperatively *)
      let _ = Tray.set_title tray ~text:"Updated" in
      ()
    ]} *)

val remove : t -> unit
(** [remove tray] immediately removes the tray item from the system tray.

    This is called automatically when the tray handle is garbage collected, but
    you can call it explicitly for immediate cleanup. *)

val set_on_click : t -> (unit -> unit) -> unit
(** [set_on_click tray callback] sets a callback function to be called when the
    tray icon is clicked.

    Example:
    {[
      let tray = Tray.make () in
      Tray.set_on_click tray (fun () -> print_endline "Tray clicked!")
    ]} *)

val poll_events : unit -> unit
(** [poll_events ()] processes any pending tray click events.

    This should be called regularly (e.g., in your event loop or animation frame
    handler) to process tray icon clicks. Click callbacks are queued and
    executed when this is called.

    Example:
    {[
      let handle_event = function
        | Ui.Event.AnimationFrame _ ->
            Tray.poll_events ();
            Some msg
        | _ ->
            None
    ]} *)

(** {2 Internal API for Subscription System} *)

type tray_message = { tray : t; dispatch : unit -> unit }
(** Internal type for subscription messages *)

val setup_subscription_callback : t -> (unit -> unit) -> unit
(** [setup_subscription_callback tray callback] sets up a callback for the
    subscription system. This is called by the runtime when a tray subscription
    becomes active. *)

val clear_subscription_callback : t -> unit
(** [clear_subscription_callback tray] clears the callback for the subscription
    system. This is called by the runtime when a tray subscription is removed.
*)

val poll_subscription_messages : unit -> tray_message list
(** [poll_subscription_messages ()] retrieves all pending subscription messages.
    This is called by the runtime each frame to process tray clicks. *)
