open Mlui

type paint_context = {
  tool : Common.Tool.t;
  foreground : Ui.Color.t;
  background : Ui.Color.t;
}

module Msg = struct
  type t =
    | OnMouseDown of {
        x : int;
        y : int;
        tool : Common.Tool.t;
        foreground : Ui.Color.t;
        background : Ui.Color.t;
      }
    | OnMouseMove of int * int
    | OnMouseUp of int * int
end

module OutMsg = struct
  type t =
    | ShapeCommitted of { start : Common.Position.t; eend : Common.Position.t }
    | PathCommitted of Common.Position.t list
end

module DrawingState = struct
  type t =
    | Idle
    | Drawing of { context : paint_context; start_position : Common.Position.t }
    | CollectingPoints of {
        context : paint_context;
        points : Common.Position.t list;
      }
end

module Model = struct
  type t = { drawing_state : DrawingState.t; preview : Common.Drawing.t option }

  let init () = { drawing_state = DrawingState.Idle; preview = None }
end

let make_context ~tool ~foreground ~background =
  { tool; foreground; background }

let update (msg : Msg.t) (model : Model.t) : Model.t * OutMsg.t option =
  match msg with
  | OnMouseDown { x; y; tool; foreground; background } -> (
      let position = Common.Position.make ~x ~y in
      let context = make_context ~tool ~foreground ~background in
      match tool with
      | Common.Tool.Pencil | Common.Tool.Brush _ | Common.Tool.Eraser _ ->
          ( {
              drawing_state =
                DrawingState.CollectingPoints { context; points = [ position ] };
              preview =
                Some
                  (Common.Drawing.make ~start:position ~eend:position ~tool
                     ~foreground ~background);
            },
            None )
      | Common.Tool.Rectangle _ | Common.Tool.Ellipse _ | Common.Tool.Line _ ->
          ( {
              drawing_state =
                DrawingState.Drawing { context; start_position = position };
              preview =
                Some
                  (Common.Drawing.make ~start:position ~eend:position ~tool
                     ~foreground ~background);
            },
            None ))
  | OnMouseMove (x, y) -> (
      let position = Common.Position.make ~x ~y in
      match model.drawing_state with
      | DrawingState.Drawing { context; start_position } ->
          let preview =
            Common.Drawing.make ~start:start_position ~eend:position
              ~tool:context.tool ~foreground:context.foreground
              ~background:context.background
          in
          ({ model with preview = Some preview }, None)
      | DrawingState.CollectingPoints { context; points } ->
          let updated_points = points @ [ position ] in
          (* Show the full path preview *)
          let preview =
            Common.Drawing.make_path ~points:updated_points ~tool:context.tool
              ~foreground:context.foreground ~background:context.background
          in
          ( {
              drawing_state =
                DrawingState.CollectingPoints
                  { context; points = updated_points };
              preview = Some preview;
            },
            None )
      | DrawingState.Idle ->
          (model, None))
  | OnMouseUp (x, y) -> (
      let position = Common.Position.make ~x ~y in
      match model.drawing_state with
      | DrawingState.Drawing { context = _; start_position } ->
          ( { drawing_state = DrawingState.Idle; preview = None },
            Some
              (OutMsg.ShapeCommitted { start = start_position; eend = position })
          )
      | DrawingState.CollectingPoints { context = _; points } ->
          let final_points = points @ [ position ] in
          ( { drawing_state = DrawingState.Idle; preview = None },
            Some (OutMsg.PathCommitted final_points) )
      | DrawingState.Idle ->
          (model, None))

module Styles = struct
  open Ui

  let canvas =
    Style.default
    |> Style.with_background Color.white
    |> Style.with_flex_grow 1.0
end

let drawing_to_primitive (drawing : Common.Drawing.t) : Ui.primitive =
  let open Common in
  match drawing.shape_data with
  | Drawing.TwoPoint { start; eend } -> (
      let x1 = float_of_int start.x in
      let y1 = float_of_int start.y in
      let x2 = float_of_int eend.x in
      let y2 = float_of_int eend.y in

      let x = min x1 x2 in
      let y = min y1 y2 in
      let width = abs_float (x2 -. x1) in
      let height = abs_float (y2 -. y1) in

      match drawing.tool with
      | Tool.Rectangle `Outline ->
          Ui.rectangle ~x ~y ~width ~height
            ~style:(Ui.stroke drawing.foreground 2.0)
      | Tool.Rectangle `Filled ->
          Ui.rectangle ~x ~y ~width ~height ~style:(Ui.fill drawing.foreground)
      | Tool.Rectangle `FilledWithOutline ->
          Ui.rectangle ~x ~y ~width ~height
            ~style:
              (Ui.fill_and_stroke drawing.background drawing.foreground 2.0)
      | Tool.Ellipse `Outline ->
          let cx = x +. (width /. 2.0) in
          let cy = y +. (height /. 2.0) in
          let rx = width /. 2.0 in
          let ry = height /. 2.0 in
          Ui.ellipse ~cx ~cy ~rx ~ry ~style:(Ui.stroke drawing.foreground 2.0)
      | Tool.Ellipse `Filled ->
          let cx = x +. (width /. 2.0) in
          let cy = y +. (height /. 2.0) in
          let rx = width /. 2.0 in
          let ry = height /. 2.0 in
          Ui.ellipse ~cx ~cy ~rx ~ry ~style:(Ui.fill drawing.foreground)
      | Tool.Ellipse `FilledWithOutline ->
          let cx = x +. (width /. 2.0) in
          let cy = y +. (height /. 2.0) in
          let rx = width /. 2.0 in
          let ry = height /. 2.0 in
          Ui.ellipse ~cx ~cy ~rx ~ry
            ~style:
              (Ui.fill_and_stroke drawing.background drawing.foreground 2.0)
      | Tool.Line thickness ->
          let points = [ (x1, y1); (x2, y2) ] in
          let width =
            match thickness with `S -> 1.0 | `M -> 3.0 | `L -> 6.0
          in
          Ui.path ~points ~style:(Ui.stroke drawing.foreground width)
      | Tool.Pencil | Tool.Brush _ | Tool.Eraser _ ->
          (* These should not appear in TwoPoint, but handle gracefully *)
          let points = [ (x1, y1); (x2, y2) ] in
          Ui.path ~points ~style:(Ui.stroke drawing.foreground 1.0))
  | Drawing.Path points ->
      let float_points =
        List.map
          (fun p -> (float_of_int p.Position.x, float_of_int p.Position.y))
          points
      in
      let width =
        match drawing.tool with
        | Tool.Brush `S ->
            2.0
        | Tool.Brush `M ->
            5.0
        | Tool.Brush `L ->
            10.0
        | Tool.Eraser `S ->
            4.0
        | Tool.Eraser `M ->
            8.0
        | Tool.Eraser `L ->
            16.0
        | Tool.Pencil ->
            1.0
        | _ ->
            2.0
      in
      let color =
        match drawing.tool with
        | Tool.Eraser _ ->
            drawing.background
        | _ ->
            drawing.foreground
      in
      Ui.path ~points:float_points ~style:(Ui.stroke color width)

let view ~(model : Model.t) ~tool ~foreground ~background ~drawings =
  let all_drawings =
    match model.preview with
    | Some preview ->
        preview :: drawings
    | None ->
        drawings
  in
  let primitives = all_drawings |> List.map drawing_to_primitive |> List.rev in
  Ui.canvas ~style:Styles.canvas
    ~on_mouse_down:(fun (x, y) ->
      Some (Msg.OnMouseDown { x; y; tool; foreground; background }))
    ~on_mouse_move:(fun (x, y) -> Some (Msg.OnMouseMove (x, y)))
    ~on_mouse_up:(fun (x, y) -> Some (Msg.OnMouseUp (x, y)))
    primitives
