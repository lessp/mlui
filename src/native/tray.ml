(** System tray implementation *)

type t

(* Global message queue for tray clicks *)
let pending_messages : (unit -> unit) Queue.t = Queue.create ()

(* Message queue for subscription-based tray clicks *)
(* This is checked by the runtime each frame *)
type tray_message = { tray : t; dispatch : unit -> unit }
let subscription_messages : tray_message Queue.t = Queue.create ()

(* External C functions *)
external make_impl : string option -> t = "mlui_tray_make"
external set_title_impl : t -> string -> t = "mlui_tray_set_title"
external remove_impl : t -> unit = "mlui_tray_remove"
external set_on_click_impl : t -> (unit -> unit) -> unit
  = "mlui_tray_set_on_click"

let is_macos () =
  match Sys.os_type with
  | "Unix" ->
      (* Check if we're on macOS by looking for characteristic paths *)
      Sys.file_exists "/System/Library/CoreServices/Finder.app"
  | _ ->
      false

let make ?image_path () =
  if not (is_macos ()) then
    (* On non-macOS platforms, log a warning but don't fail *)
    Printf.eprintf "[Tray] Warning: Tray support is only available on macOS\n%!";

  let tray = make_impl image_path in

  (* Register finalizer to clean up when GC collects this value *)
  Gc.finalise
    (fun t ->
      try remove_impl t
      with _ ->
        (* Suppress errors during finalization *)
        ())
    tray;

  tray

let set_title tray ~text = set_title_impl tray text

let remove tray = remove_impl tray

let set_on_click tray on_click =
  (* Wrap callback to queue messages for main thread *)
  set_on_click_impl tray (fun () -> Queue.add on_click pending_messages)

let poll_events () =
  (* Process all pending messages *)
  while not (Queue.is_empty pending_messages) do
    let msg_fn = Queue.take pending_messages in
    msg_fn ()
  done

(* Internal function for subscription system *)
let setup_subscription_callback tray on_msg =
  set_on_click_impl tray (fun () ->
      Queue.add { tray; dispatch = on_msg } subscription_messages)

(* Internal function for subscription system *)
let clear_subscription_callback tray = set_on_click_impl tray (fun () -> ())

(* Internal function for subscription system - called by runtime *)
let poll_subscription_messages () =
  let messages = ref [] in
  while not (Queue.is_empty subscription_messages) do
    let msg = Queue.take subscription_messages in
    messages := msg :: !messages
  done;
  List.rev !messages
