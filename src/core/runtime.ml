open Tsdl
open Types

let ( let* ) result f =
  match result with Ok x -> f x | Error (`Msg _ as err) -> Error err

module Renderer = Renderer.Renderer

module Engine = struct
  let mouse_button_of_sdl = function
    | 1 ->
        Ui_event.Left
    | 2 ->
        Ui_event.Middle
    | 3 ->
        Ui_event.Right
    | _ ->
        Ui_event.Left

  let event_of_sdl show_fps_ref sdl_event =
    match Sdl.Event.(enum (get sdl_event typ)) with
    | `Quit ->
        Some Ui_event.Quit
    | `Mouse_button_down ->
        let x, y, button =
          Sdl.Event.
            ( get sdl_event mouse_button_x,
              get sdl_event mouse_button_y,
              get sdl_event mouse_button_button )
        in
        Some (Ui_event.MouseDown { x; y; button = mouse_button_of_sdl button })
    | `Mouse_button_up ->
        let x, y, button =
          Sdl.Event.
            ( get sdl_event mouse_button_x,
              get sdl_event mouse_button_y,
              get sdl_event mouse_button_button )
        in
        Some (Ui_event.MouseUp { x; y; button = mouse_button_of_sdl button })
    | `Mouse_motion ->
        let x, y =
          Sdl.Event.(get sdl_event mouse_motion_x, get sdl_event mouse_motion_y)
        in
        Some (Ui_event.MouseMove { x; y })
    | `Key_down ->
        let keycode = Sdl.Event.(get sdl_event keyboard_keycode) in
        let key_name = Sdl.get_key_name keycode in
        if key_name = "F3" then (
          show_fps_ref := not !show_fps_ref;
          None
        ) else
          Some (Ui_event.KeyDown key_name)
    | `Key_up ->
        let keycode = Sdl.Event.(get sdl_event keyboard_keycode) in
        Some (Ui_event.KeyUp (Sdl.get_key_name keycode))
    | _ ->
        None

  let run ~(window : Window.t) ~init ~update ~view ~subscriptions ~is_quit
      ~render : (unit, [> `Msg of string ]) result =
    let width = window.width in
    let height = window.height in
    let window_title = window.title in

    let* () = Sdl.init Sdl.Init.(video + events) in

    Sdl.gl_set_attribute Sdl.Gl.context_major_version 2 |> ignore;
    Sdl.gl_set_attribute Sdl.Gl.context_minor_version 1 |> ignore;

    let* window =
      Sdl.create_window window_title ~w:width ~h:height
        Sdl.Window.(opengl + resizable)
    in

    let* gl_context = Sdl.gl_create_context window in
    let* () = Sdl.gl_make_current window gl_context in

    let renderer_state = Renderer.create ~width ~height in

    let model = ref init in
    let event = Sdl.Event.create () in
    let node_tree = ref None in
    let hovered_path = ref None in
    let active_subs = ref Subscription.none in
    let has_animation_frame_sub = ref false in
    let active_tray_subs : (Tray.t * (unit -> unit)) list ref = ref [] in

    (* Helper to execute commands *)
    let rec execute_cmd cmd =
      match cmd with
      | Cmd.ShowWindow ->
          Printf.printf "[Runtime] Executing ShowWindow\n%!";
          Sdl.show_window window
      | Cmd.HideWindow ->
          Printf.printf "[Runtime] Executing HideWindow\n%!";
          Sdl.hide_window window
      | Cmd.None -> ()
      | Cmd.Batch cmds -> List.iter execute_cmd cmds
    in

    let dispatch_to_node event node_info =
      match
        Events.handle_node_event_with_bounds event node_info.node
          node_info.bounds
      with
      | Some msg ->
          let new_model, cmd = update msg !model in
          model := new_model;
          execute_cmd cmd;
          true
      | None ->
          false
    in

    let frame_count = ref 0 in
    let last_fps_time = ref (Sdl.get_ticks ()) in
    let last_frame_time = ref (Sdl.get_ticks ()) in
    let current_fps = ref 0.0 in
    let show_fps = ref false in
    let debug_layout = Sys.getenv_opt "UI_DEBUG_LAYOUT" <> None in
    let last_layout_log = ref 0l in

    let rec loop () =
      incr frame_count;
      let current_time = Sdl.get_ticks () in
      let frame_delta = Int32.sub current_time !last_frame_time in
      let delta_seconds = Int32.to_float frame_delta /. 1000.0 in
      last_frame_time := current_time;
      let time_diff = Int32.sub current_time !last_fps_time in
      if Int32.compare time_diff 1000l >= 0 then begin
        let calculated_fps =
          float_of_int !frame_count *. 1000.0 /. Int32.to_float time_diff
        in
        current_fps := min calculated_fps 60.0;
        frame_count := 0;
        last_fps_time := current_time
      end;

      let current_width, current_height = Sdl.get_window_size window in
      let scene = view !model in
      let tree_with_bounds, render_primitives =
        Layout.layout_with_bounds_and_primitives ~width:current_width
          ~height:current_height scene
      in
      node_tree := Some tree_with_bounds;
      if debug_layout then begin
        let now = Sdl.get_ticks () in
        if Int32.sub now !last_layout_log >= 500l then begin
          last_layout_log := now;
          let bounds = tree_with_bounds.bounds in
          Printf.printf "[ui] root layout: (x=%.1f, y=%.1f, w=%.1f, h=%.1f)\n"
            bounds.x bounds.y bounds.width bounds.height;
          let rec dump depth node =
            let indent = String.make (depth * 2) ' ' in
            let b = node.bounds in
            Printf.printf "%s- x=%.1f y=%.1f w=%.1f h=%.1f\n" indent b.x b.y
              b.width b.height;
            List.iter (dump (depth + 1)) node.children
          in
          dump 0 tree_with_bounds;
          flush stdout
        end
      end;
      (match !hovered_path with
      | Some path ->
          if Option.is_none (Events.find_node_by_path path tree_with_bounds)
          then
            hovered_path := None
      | None ->
          ());

      let fps_to_show =
        if !show_fps then
          !current_fps
        else
          0.0
      in
      render ~fps:fps_to_show renderer_state render_primitives;
      Sdl.gl_swap_window window;

      (* Update subscriptions based on current model *)
      let new_subs = subscriptions !model in
      if not (Subscription.equal !active_subs new_subs) then begin
        (* Subscriptions changed - update our tracking *)
        active_subs := new_subs;
        (* Check if we have an animation frame subscription *)
        let flattened = Subscription.flatten new_subs in
        has_animation_frame_sub := List.exists (function
          | Subscription.AnimationFrame _ -> true
          | _ -> false
        ) flattened;

        (* Update tray subscriptions *)
        let new_tray_subs = List.filter_map (function
          | Subscription.TrayClick (tray, msg) ->
              Some (tray, (fun () ->
                Printf.printf "[Runtime] Tray callback fired\n%!";
                let new_model, cmd = update msg !model in
                model := new_model;
                execute_cmd cmd))
          | _ -> None
        ) flattened in

        Printf.printf "[Runtime] Tray subs - old: %d, new: %d\n%!"
          (List.length !active_tray_subs) (List.length new_tray_subs);

        (* Clear old tray subscriptions that are no longer active *)
        List.iter (fun (tray, _) ->
          if not (List.exists (fun (t, _) -> t == tray) new_tray_subs) then begin
            Printf.printf "[Runtime] Clearing tray subscription\n%!";
            Tray.clear_subscription_callback tray
          end
        ) !active_tray_subs;

        (* Setup new tray subscriptions *)
        List.iter (fun (tray, callback) ->
          Printf.printf "[Runtime] Setting up tray subscription\n%!";
          Tray.setup_subscription_callback tray callback
        ) new_tray_subs;

        active_tray_subs := new_tray_subs;
      end;

      (* Process animation frame subscription *)
      if !has_animation_frame_sub then begin
        let flattened = Subscription.flatten !active_subs in
        List.iter (function
          | Subscription.AnimationFrame f ->
              let msg = f delta_seconds in
              let new_model, cmd = update msg !model in
              model := new_model;
              execute_cmd cmd
          | _ -> ()
        ) flattened;
      end;

      (* Process tray subscription messages *)
      let tray_messages = Tray.poll_subscription_messages () in
      List.iter (fun msg -> msg.Tray.dispatch ()) tray_messages;

      (* Process quit subscription *)
      let has_quit_sub = ref false in
      let flattened = Subscription.flatten !active_subs in
      List.iter (function
        | Subscription.Quit _ -> has_quit_sub := true
        | _ -> ()
      ) flattened;



      match Sdl.poll_event (Some event) with
      | false ->
          loop ()
      | true -> (
          match event_of_sdl show_fps event with
          | Some ev when is_quit ev ->
              (* Process quit subscription first *)
              if !has_quit_sub then begin
                let flattened = Subscription.flatten !active_subs in
                List.iter (function
                  | Subscription.Quit msg ->
                      let new_model, cmd = update msg !model in
                      model := new_model;
                      execute_cmd cmd
                  | _ -> ()
                ) flattened;
              end;
              ()
          | Some ev ->
              (* First, check if subscriptions can handle this event *)
              let sub_handled = ref false in
              (match ev with
              | Ui_event.KeyUp key_name ->
                  let flattened = Subscription.flatten !active_subs in
                  List.iter (function
                    | Subscription.KeyUp f ->
                        let msg = f key_name in
                        let new_model, cmd = update msg !model in
                        model := new_model;
                        execute_cmd cmd;
                        sub_handled := true
                    | _ -> ()
                  ) flattened
              | Ui_event.KeyDown key_name ->
                  let flattened = Subscription.flatten !active_subs in
                  List.iter (function
                    | Subscription.KeyDown f ->
                        let msg = f key_name in
                        let new_model, cmd = update msg !model in
                        model := new_model;
                        execute_cmd cmd;
                        sub_handled := true
                    | _ -> ()
                  ) flattened
              | Ui_event.MouseDown { x; y; _ } ->
                  let flattened = Subscription.flatten !active_subs in
                  List.iter (function
                    | Subscription.MouseDown f ->
                        let msg = f x y in
                        let new_model, cmd = update msg !model in
                        model := new_model;
                        execute_cmd cmd;
                        sub_handled := true
                    | _ -> ()
                  ) flattened
              | Ui_event.MouseUp { x; y; _ } ->
                  let flattened = Subscription.flatten !active_subs in
                  List.iter (function
                    | Subscription.MouseUp f ->
                        let msg = f x y in
                        let new_model, cmd = update msg !model in
                        model := new_model;
                        execute_cmd cmd;
                        sub_handled := true
                    | _ -> ()
                  ) flattened
              | Ui_event.MouseMove { x; y } ->
                  let flattened = Subscription.flatten !active_subs in
                  List.iter (function
                    | Subscription.MouseMove f ->
                        let msg = f x y in
                        let new_model, cmd = update msg !model in
                        model := new_model;
                        execute_cmd cmd;
                        sub_handled := true
                    | _ -> ()
                  ) flattened
              | _ -> ());

              let ui_handled =
                match (!node_tree, ev) with
                | Some tree, Ui_event.MouseDown { x; y; _ }
                | Some tree, Ui_event.MouseUp { x; y; _ } -> (
                    let pos = Position.make ~x ~y in
                    match Events.find_node_at_position pos tree with
                    | Some node_info ->
                        dispatch_to_node ev node_info
                    | None ->
                        false)
                | Some tree, (Ui_event.MouseMove _ as move) ->
                    Events.handle_mouse_motion ~tree ~hovered_path
                      ~dispatch_to_node move
                | _ ->
                    false
              in
              if not ui_handled && not !sub_handled then
                loop ()
              else
                loop ()
          | None ->
              loop ())
    in

    loop ();

    Sdl.gl_delete_context gl_context;
    Sdl.destroy_window window;
    Sdl.quit ();

    Ok ()
end

let run ~window ?subscriptions ~init ~update ~view () =
  let subscriptions =
    match subscriptions with Some s -> s | None -> fun _ -> Subscription.none
  in
  let is_quit = function Ui_event.Quit -> true | _ -> false in
  let render ~fps state primitives =
    Renderer.render_view_with_primitives ~fps state primitives ()
  in
  let window_config = window in
  Engine.run ~window:window_config ~init ~update ~view
    ~subscriptions ~is_quit ~render
