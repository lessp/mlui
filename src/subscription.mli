(** Subscription system for managing external event sources in mlui.

    Subscriptions are declarative requests to listen to events. The runtime
    manages the actual subscription lifecycle (start, stop, diff).

    This is inspired by Elm's subscription architecture.

    Phase 1: Only AnimationFrame is supported. More subscriptions will be added
    incrementally. *)

(** {1 Core Types} *)

type 'msg t =
  | None
  | Batch of 'msg t list
  | AnimationFrame of (float -> 'msg)
  | KeyUp of (string -> 'msg)
  | KeyDown of (string -> 'msg)
  | MouseDown of (int -> int -> 'msg)
  | MouseUp of (int -> int -> 'msg)
  | MouseMove of (int -> int -> 'msg)
  | TrayClick of (Tray.t * 'msg)
  | Quit of 'msg
      (** A subscription that can produce messages of type ['msg].

          Subscriptions are declarative - they describe what you want to listen
          to, and the runtime manages the actual listening.

          The constructors are exposed to allow the runtime to pattern match on
          them. *)

(** {1 Basic Subscriptions} *)

val none : 'msg t
(** No subscription. Use this when you don't need to listen to anything.

    Example:
    {[
      let subscriptions model =
        if model.running then
          Sub.on_animation_frame (fun dt -> Tick dt)
        else
          Sub.none
    ]} *)

val batch : 'msg t list -> 'msg t
(** Combine multiple subscriptions into one.

    Example:
    {[
      let subscriptions model =
        Sub.batch
          [
            Sub.on_animation_frame (fun dt -> Tick dt);
            (* More subscriptions will be added in future phases *)
          ]
    ]} *)

(** {1 Time Subscriptions} *)

val on_animation_frame : (float -> 'msg) -> 'msg t
(** Subscribe to animation frame events (~60fps). The callback receives the
    delta time in seconds since the last frame.

    Example:
    {[
      let subscriptions model =
        Sub.on_animation_frame (fun delta -> Msg.Tick delta)
    ]} *)

(** {1 Application Subscriptions} *)

val on_quit : 'msg -> 'msg t
(** Subscribe to application quit events.

    When the user tries to quit the application, the provided message will be
    dispatched.

    Example:
    {[
      let subscriptions model = Sub.on_quit Msg.Quit
    ]} *)

(** {1 Keyboard Subscriptions} *)

val on_key_up : (string -> 'msg) -> 'msg t
(** Subscribe to key up events. The callback receives the key name as a string
    (e.g., "Space", "A", "Escape").

    Example:
    {[
      let subscriptions model = Sub.on_key_up (fun key -> Msg.KeyReleased key)
    ]} *)

val on_key_down : (string -> 'msg) -> 'msg t
(** Subscribe to key down events. The callback receives the key name as a string
    (e.g., "Space", "A", "Escape").

    Example:
    {[
      let subscriptions model = Sub.on_key_down (fun key -> Msg.KeyPressed key)
    ]} *)

(** {1 Mouse Subscriptions} *)

val on_mouse_down : (int -> int -> 'msg) -> 'msg t
(** Subscribe to mouse button down events. The callback receives the x and y
    coordinates of the mouse click.

    Example:
    {[
      let subscriptions model =
        Sub.on_mouse_down (fun x y -> Msg.MousePressed (x, y))
    ]} *)

val on_mouse_up : (int -> int -> 'msg) -> 'msg t
(** Subscribe to mouse button up events. The callback receives the x and y
    coordinates where the button was released.

    Example:
    {[
      let subscriptions model =
        Sub.on_mouse_up (fun x y -> Msg.MouseReleased (x, y))
    ]} *)

val on_mouse_move : (int -> int -> 'msg) -> 'msg t
(** Subscribe to mouse move events. The callback receives the current x and y
    coordinates of the mouse.

    Note: This can fire very frequently. Use with care.

    Example:
    {[
      let subscriptions model =
        if model.tracking then
          Sub.on_mouse_move (fun x y -> Msg.MouseMoved (x, y))
        else
          Sub.none
    ]} *)

(** {1 System Tray Subscriptions} *)

module Tray : sig
  val on_click : Tray.t -> 'msg -> 'msg t
  (** Subscribe to system tray icon click events.

      When the tray icon is clicked, the provided message will be dispatched.

      Example:
      {[
        type model = { tray : Tray.t option; ... }
        type msg = TrayClicked | ...

        let subscriptions model =
          match model.tray with
          | Some tray -> Sub.Tray.on_click tray TrayClicked
          | None -> Sub.none
      ]}

      Note: The subscription is automatically managed based on your model state.
      When the tray handle changes or is removed, the subscription updates
      accordingly. *)
end

(** {1 Internal API} *)

val equal : 'msg t -> 'msg2 t -> bool
(** Compare two subscriptions for structural equality (ignoring the message
    type). Used by the runtime to diff subscriptions. *)

val flatten : 'msg t -> 'msg t list
(** Flatten nested batch subscriptions into a flat list. Used by the runtime to
    process subscriptions. *)
