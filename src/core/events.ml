open Types

let point_in_bounds (pos : Position.t) (bounds : bounds) : bool =
  let x = float_of_int pos.x in
  let y = float_of_int pos.y in
  x >= bounds.x
  && x < bounds.x +. bounds.width
  && y >= bounds.y
  && y < bounds.y +. bounds.height

let rec find_node_at_position (pos : Position.t)
    (node_with_bounds : 'msg node_with_bounds) : 'msg node_with_bounds option =
  let rec check_children = function
    | [] ->
        None
    | child :: rest -> (
        match find_node_at_position pos child with
        | Some result ->
            Some result
        | None ->
            check_children rest)
  in
  match check_children (List.rev node_with_bounds.children) with
  | Some result ->
      Some result
  | None ->
      if point_in_bounds pos node_with_bounds.bounds then
        Some node_with_bounds
      else
        None

let rec find_node_by_path (path : path)
    (node_with_bounds : 'msg node_with_bounds) : 'msg node_with_bounds option =
  match path with
  | [] ->
      Some node_with_bounds
  | index :: rest -> (
      let rec nth idx = function
        | [] ->
            None
        | child :: tail ->
            if idx = 0 then
              Some child
            else
              nth (idx - 1) tail
      in
      match nth index node_with_bounds.children with
      | Some child ->
          find_node_by_path rest child
      | None ->
          None)

let handle_node_event_with_bounds (event : Ui_event.t)
    (node : 'msg interactive_node) (bounds : bounds) : 'msg option =
  let transform_coords x y =
    let rel_x = float_of_int x -. bounds.x in
    let rel_y = float_of_int y -. bounds.y in
    (int_of_float rel_x, int_of_float rel_y)
  in
  match (event, node) with
  | ( Ui_event.MouseDown { button = Ui_event.Left; _ },
      View { on_click = Some handler; _ } ) ->
      handler ()
  | Ui_event.MouseDown { x; y; _ }, View { on_mouse_down = Some handler; _ }
  | Ui_event.MouseUp { x; y; _ }, View { on_mouse_up = Some handler; _ }
  | Ui_event.MouseMove { x; y }, View { on_mouse_move = Some handler; _ }
  | Ui_event.MouseEnter { x; y }, View { on_mouse_enter = Some handler; _ }
  | Ui_event.MouseLeave { x; y }, View { on_mouse_leave = Some handler; _ }
  | Ui_event.MouseDown { x; y; _ }, Canvas { on_mouse_down = Some handler; _ }
  | Ui_event.MouseUp { x; y; _ }, Canvas { on_mouse_up = Some handler; _ }
  | Ui_event.MouseMove { x; y }, Canvas { on_mouse_move = Some handler; _ }
  | Ui_event.MouseEnter { x; y }, Canvas { on_mouse_enter = Some handler; _ }
  | Ui_event.MouseLeave { x; y }, Canvas { on_mouse_leave = Some handler; _ } ->
      let rel_x, rel_y = transform_coords x y in
      handler (rel_x, rel_y)
  | ( Ui_event.MouseDown { button = Ui_event.Left; _ },
      Canvas { on_click = Some handler; _ } ) ->
      handler ()
  | ( Ui_event.MouseDown { button = Ui_event.Left; _ },
      Text { on_click = Some handler; _ } ) ->
      handler ()
  | _ ->
      None

let handle_mouse_motion ~tree ~hovered_path ~dispatch_to_node (move : Ui_event.t) =
  match move with
  | Ui_event.MouseMove { x; y } ->
      let pos = Position.make ~x ~y in
      let current_node = find_node_at_position pos tree in
      let handled = ref false in
      let dispatch event node_info =
        if dispatch_to_node event node_info then handled := true
      in
      (match !hovered_path with
      | Some prev_path -> (
          match current_node with
          | Some node when node.path = prev_path ->
              ()
          | _ -> (
              match find_node_by_path prev_path tree with
              | Some prev_node ->
                  dispatch (Ui_event.MouseLeave { x; y }) prev_node;
                  hovered_path := None
              | None ->
                  hovered_path := None))
      | None ->
          ());
      (match current_node with
      | Some node ->
          if Some node.path <> !hovered_path then
            dispatch (Ui_event.MouseEnter { x; y }) node;
          hovered_path := Some node.path;
          dispatch move node
      | None ->
          hovered_path := None);
      !handled
  | _ ->
      false
