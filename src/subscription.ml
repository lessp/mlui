(** Subscription system for managing external event sources *)

(* A subscription represents a declarative request to listen to an event source.
   The runtime manages the actual subscription lifecycle. *)
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

(* Subscription constructors *)

let none = None

let batch subs =
  match List.filter (fun s -> s <> None) subs with
  | [] -> None
  | [single] -> single
  | many -> Batch many

(* Time subscriptions *)

let on_animation_frame f = AnimationFrame f

(* Application subscriptions *)

let on_quit msg = Quit msg

(* Keyboard subscriptions *)

let on_key_up f = KeyUp f

let on_key_down f = KeyDown f

(* Mouse subscriptions *)

let on_mouse_down f = MouseDown f

let on_mouse_up f = MouseUp f

let on_mouse_move f = MouseMove f

(* Tray subscriptions *)

module Tray = struct
  let on_click tray msg = TrayClick (tray, msg)
end

(* Subscription comparison for diffing *)

let rec equal : 'msg 'msg2. 'msg t -> 'msg2 t -> bool = fun s1 s2 ->
  match s1, s2 with
  | None, None -> true
  | AnimationFrame _, AnimationFrame _ -> true
  | KeyUp _, KeyUp _ -> true
  | KeyDown _, KeyDown _ -> true
  | MouseDown _, MouseDown _ -> true
  | MouseUp _, MouseUp _ -> true
  | MouseMove _, MouseMove _ -> true
  | TrayClick (t1, _), TrayClick (t2, _) -> t1 == t2
  | Quit _, Quit _ -> true
  | Batch subs1, Batch subs2 ->
      List.length subs1 = List.length subs2 &&
      List.for_all2 equal subs1 subs2
  | _ -> false

(* Flatten nested batches *)
let rec flatten : 'msg t -> 'msg t list = function
  | None -> []
  | Batch subs -> List.concat_map flatten subs
  | sub -> [sub]
