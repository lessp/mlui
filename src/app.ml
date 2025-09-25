module Msg = struct
  type t =
    | MouseDown of int * int
    | MouseMove of int * int
    | MouseUp of int * int
    | KeyPress of char
    | ToolbarMsg of Toolbar.Msg.t
    | Quit
end

module Model = struct
  type t = {
    drawing_state : DrawingState.t;
    current_position : Shape.Position.t;
    completed_shapes : Shape.t list;
    preview_shape : Shape.t option;
    toolbar : Toolbar.Model.t;
  }

  let default () = {
    drawing_state = DrawingState.Idle;
    current_position = Shape.Position.make ~x:0 ~y:0;
    completed_shapes = [];
    preview_shape = None;
    toolbar = Toolbar.Model.default ();
  }

  (* Helper functions to get current tool/colors from toolbar *)
  let get_current_tool model = model.toolbar.selected_tool
  let get_current_swatch model =
    ColorSwatch.make
      ~foreground:model.toolbar.foreground_color
      ~background:model.toolbar.background_color
end

let create_rectangle_from_drag start_pos end_pos =
  let x = min start_pos.Shape.Position.x end_pos.Shape.Position.x in
  let y = min start_pos.Shape.Position.y end_pos.Shape.Position.y in
  let width = abs (end_pos.Shape.Position.x - start_pos.Shape.Position.x) in
  let height = abs (end_pos.Shape.Position.y - start_pos.Shape.Position.y) in
  Shape.rectangle ~x ~y ~width ~height

let update (msg : Msg.t) (model : Model.t) =
  match msg with
  | MouseDown (x, y) ->
    let pos = Shape.Position.make ~x ~y in
    (* Check if click is on toolbar first *)
    (match Toolbar.Model.get_tool_at_position model.toolbar pos with
     | Some tool ->
       (* Clicked on a tool - update toolbar *)
       let new_toolbar = Toolbar.update (Toolbar.Msg.SelectTool tool) model.toolbar in
       { model with toolbar = new_toolbar }
     | None ->
       (* Clicked on canvas - start drawing *)
       let current_tool = Model.get_current_tool model in
       (match current_tool with
        | Tool.Rectangle _ ->
          { model with
            drawing_state = DrawingState.DrawingRectangle { start_pos = pos };
            current_position = pos;
            preview_shape = Some (Shape.rectangle ~x ~y ~width:0 ~height:0) }
        | _ -> { model with current_position = pos }))

  | MouseMove (x, y) ->
    let pos = Shape.Position.make ~x ~y in
    (* Check if hovering over toolbar *)
    let hovered_tool = Toolbar.Model.get_tool_at_position model.toolbar pos in
    let new_toolbar = Toolbar.update (Toolbar.Msg.HoverTool hovered_tool) model.toolbar in

    (match model.drawing_state with
     | DrawingState.DrawingRectangle { start_pos } ->
       let preview_rect = create_rectangle_from_drag start_pos pos in
       { model with
         current_position = pos;
         preview_shape = Some preview_rect;
         toolbar = new_toolbar }
     | DrawingState.Idle ->
       { model with
         current_position = pos;
         toolbar = new_toolbar })

  | MouseUp (x, y) ->
    let pos = Shape.Position.make ~x ~y in
    (match model.drawing_state with
     | DrawingState.DrawingRectangle { start_pos } ->
       let final_rect = create_rectangle_from_drag start_pos pos in
       { model with
         drawing_state = DrawingState.Idle;
         current_position = pos;
         completed_shapes = final_rect :: model.completed_shapes;
         preview_shape = None }
     | DrawingState.Idle -> { model with current_position = pos })

  | ToolbarMsg toolbar_msg ->
    let new_toolbar = Toolbar.update toolbar_msg model.toolbar in
    { model with toolbar = new_toolbar }

  | KeyPress _ -> model
  | Quit -> model
