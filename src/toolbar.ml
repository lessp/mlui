module Msg = struct
  type t =
    | SelectTool of Tool.t
    | SelectForegroundColor of Color.t
    | SelectBackgroundColor of Color.t
    | HoverTool of Tool.t option
    | ToggleExpanded
end

module Model = struct
  type t = {
    selected_tool : Tool.t;
    foreground_color : Color.t;
    background_color : Color.t;
    hovered_tool : Tool.t option;
    expanded : bool;
    position : Shape.Position.t;
    size : Shape.Size.t;
  }

  let default () = {
    selected_tool = Tool.Rectangle Tool.FillStyle.Filled;
    foreground_color = Color.black;
    background_color = Color.white;
    hovered_tool = None;
    expanded = true;
    position = Shape.Position.make ~x:10 ~y:10;
    size = Shape.Size.make ~width:60 ~height:400;
  }

  (* Helper functions *)
  let tool_button_size = 24
  let tool_button_padding = 4
  let tools_per_row = 2

  let available_tools = [
    Tool.Rectangle Tool.FillStyle.Filled;
    Tool.Rectangle Tool.FillStyle.Outline;
    Tool.Ellipse Tool.FillStyle.Filled;
    Tool.Ellipse Tool.FillStyle.Outline;
    Tool.Pencil;
    Tool.Brush (Tool.BrushShape.Rectangle Tool.BrushShape.Thickness.Medium);
  ]

  let get_tool_position model tool_index =
    let row = tool_index / tools_per_row in
    let col = tool_index mod tools_per_row in
    let x = model.position.x + col * (tool_button_size + tool_button_padding) + tool_button_padding in
    let y = model.position.y + row * (tool_button_size + tool_button_padding) + tool_button_padding in
    Shape.Position.make ~x ~y

  let get_tool_at_position model pos =
    if not model.expanded then None
    else
      let rec check_tools tools index =
        match tools with
        | [] -> None
        | tool :: rest ->
          let tool_pos = get_tool_position model index in
          let in_bounds =
            pos.Shape.Position.x >= tool_pos.x &&
            pos.Shape.Position.x < tool_pos.x + tool_button_size &&
            pos.Shape.Position.y >= tool_pos.y &&
            pos.Shape.Position.y < tool_pos.y + tool_button_size
          in
          if in_bounds then Some tool
          else check_tools rest (index + 1)
      in
      check_tools available_tools 0
end

let update msg model =
  match msg with
  | Msg.SelectTool tool ->
    { model with Model.selected_tool = tool; hovered_tool = None }

  | Msg.SelectForegroundColor color ->
    { model with Model.foreground_color = color }

  | Msg.SelectBackgroundColor color ->
    { model with Model.background_color = color }

  | Msg.HoverTool tool_opt ->
    { model with Model.hovered_tool = tool_opt }

  | Msg.ToggleExpanded ->
    { model with Model.expanded = not model.Model.expanded }

(* View function - returns shapes to render *)
let view model =
  if not model.Model.expanded then []
  else
    (* Background panel *)
    let bg_shape = Shape.rectangle
      ~x:model.Model.position.x
      ~y:model.Model.position.y
      ~width:model.Model.size.width
      ~height:model.Model.size.height in

    (* Tool buttons *)
    let tool_shapes = List.mapi (fun index tool ->
      let pos = Model.get_tool_position model index in
      let is_selected = tool = model.Model.selected_tool in
      let is_hovered = Some tool = model.Model.hovered_tool in

      (* Button background - different color if selected/hovered *)
      let button_bg = Shape.rectangle
        ~x:pos.x
        ~y:pos.y
        ~width:Model.tool_button_size
        ~height:Model.tool_button_size in

      (button_bg, is_selected, is_hovered)
    ) Model.available_tools in

    (* Color swatches *)
    let fg_swatch = Shape.rectangle ~x:(model.Model.position.x + 10) ~y:(model.Model.position.y + 300) ~width:20 ~height:20 in
    let bg_swatch = Shape.rectangle ~x:(model.Model.position.x + 35) ~y:(model.Model.position.y + 300) ~width:20 ~height:20 in

    (* Return all shapes with their styling info *)
    (bg_shape, `Background) ::
    (fg_swatch, `Foreground) ::
    (bg_swatch, `BackgroundSwatch) ::
    (List.map (fun (shape, selected, hovered) ->
      if selected then (shape, `Selected)
      else if hovered then (shape, `Hovered)
      else (shape, `Normal)) tool_shapes)
