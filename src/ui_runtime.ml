open Tsdl
open Ui_types

let ( let* ) result f =
  match result with Ok x -> f x | Error (`Msg _ as err) -> Error err

module Renderer = Ui_renderer.Renderer

module Engine = struct
  let mouse_button_of_sdl = function
    | 1 ->
        Event.Left
    | 2 ->
        Event.Middle
    | 3 ->
        Event.Right
    | _ ->
        Event.Left

  let event_of_sdl show_fps_ref sdl_event =
    match Sdl.Event.(enum (get sdl_event typ)) with
    | `Quit ->
        Some Event.Quit
    | `Mouse_button_down ->
        let x, y, button =
          Sdl.Event.
            ( get sdl_event mouse_button_x,
              get sdl_event mouse_button_y,
              get sdl_event mouse_button_button )
        in
        Some (Event.MouseDown { x; y; button = mouse_button_of_sdl button })
    | `Mouse_button_up ->
        let x, y, button =
          Sdl.Event.
            ( get sdl_event mouse_button_x,
              get sdl_event mouse_button_y,
              get sdl_event mouse_button_button )
        in
        Some (Event.MouseUp { x; y; button = mouse_button_of_sdl button })
    | `Mouse_motion ->
        let x, y =
          Sdl.Event.(get sdl_event mouse_motion_x, get sdl_event mouse_motion_y)
        in
        Some (Event.MouseMove { x; y })
    | `Key_down ->
        let keycode = Sdl.Event.(get sdl_event keyboard_keycode) in
        let key_name = Sdl.get_key_name keycode in
        if key_name = "F3" then (
          show_fps_ref := not !show_fps_ref;
          None
        ) else
          None
    | `Key_up ->
        let keycode = Sdl.Event.(get sdl_event keyboard_keycode) in
        Some (Event.KeyUp (Sdl.get_key_name keycode))
    | _ ->
        None

  let run ~(window : Window.t) ~initial ~update ~view ~handle_event ~is_quit
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

    let model = ref initial in
    let event = Sdl.Event.create () in
    let node_tree = ref None in
    let hovered_path = ref None in
    let dispatch_to_node event node_info =
      match
        Ui_events.handle_node_event_with_bounds event node_info.node
          node_info.bounds
      with
      | Some msg ->
          model := update msg !model;
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
        Ui_layout.layout_with_bounds_and_primitives ~width:current_width
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
          if Option.is_none (Ui_events.find_node_by_path path tree_with_bounds)
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

      (* Emit AnimationFrame event first *)
      let animation_frame_ev = Event.AnimationFrame delta_seconds in
      (match handle_event animation_frame_ev with
      | Some msg ->
          model := update msg !model
      | None ->
          ());

      match Sdl.poll_event (Some event) with
      | false ->
          loop ()
      | true -> (
          match event_of_sdl show_fps event with
          | Some ev when is_quit ev ->
              (match handle_event ev with
              | Some msg ->
                  model := update msg !model
              | None ->
                  ());
              ()
          | Some ev ->
              let ui_handled =
                match (!node_tree, ev) with
                | Some tree, Event.MouseDown { x; y; _ }
                | Some tree, Event.MouseUp { x; y; _ } -> (
                    let pos = Position.make ~x ~y in
                    match Ui_events.find_node_at_position pos tree with
                    | Some node_info ->
                        dispatch_to_node ev node_info
                    | None ->
                        false)
                | Some tree, (Event.MouseMove _ as move) ->
                    Ui_events.handle_mouse_motion ~tree ~hovered_path
                      ~dispatch_to_node move
                | _ ->
                    false
              in
              if not ui_handled then
                match handle_event ev with
                | Some msg ->
                    model := update msg !model;
                    loop ()
                | None ->
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

let run ~window ?handle_event ~model ~update ~view () =
  let handle_event =
    match handle_event with Some h -> h | None -> fun _ -> None
  in
  let is_quit = function Event.Quit -> true | _ -> false in
  let render ~fps state primitives =
    Renderer.render_view_with_primitives ~fps state primitives ()
  in
  let window_config = window in
  Engine.run ~window:window_config ~initial:model ~update ~view ~handle_event
    ~is_quit ~render
