open Types

module Renderer = struct
  let load_font name =
    let ic = open_in_bin name in
    let dim = in_channel_length ic in
    let fd = Unix.descr_of_in_channel ic in
    let buffer =
      Unix.map_file fd Bigarray.int8_unsigned Bigarray.c_layout false [| dim |]
      |> Bigarray.array1_of_genarray
    in
    let offset = List.hd (Stb_truetype.enum buffer) in
    match Stb_truetype.init buffer offset with
    | None ->
        assert false
    | Some font ->
        font

  let default_font =
    lazy
      (try Some (load_font "src/assets/Roboto-Regular.ttf")
       with _ ->
         Printf.eprintf "Warning: Could not load font file\n";
         None)

  type state = {
    wall_renderer : Wall.Renderer.t;
    width : float;
    height : float;
  }

  let create ~width ~height =
    let wall_renderer = Wall.Renderer.create ~antialias:true () in
    { wall_renderer; width = float_of_int width; height = float_of_int height }

  let color_to_paint (color : Color.t) =
    Wall.Paint.rgba
      (float_of_int color.r /. 255.0)
      (float_of_int color.g /. 255.0)
      (float_of_int color.b /. 255.0)
      (float_of_int color.a /. 255.0)

  let render_shape_fill bounds = function
    | `Rectangle ->
        Wall.Image.fill_path (fun ctx ->
            Wall.Path.rect ctx ~x:bounds.x ~y:bounds.y ~w:bounds.width
              ~h:bounds.height)
    | `RoundedRectangle radius ->
        Wall.Image.fill_path (fun ctx ->
            Wall.Path.round_rect ctx ~x:bounds.x ~y:bounds.y ~w:bounds.width
              ~h:bounds.height ~r:radius)
    | `Circle ->
        let cx = bounds.x +. (bounds.width /. 2.0) in
        let cy = bounds.y +. (bounds.height /. 2.0) in
        let radius = Float.min bounds.width bounds.height /. 2.0 in
        Wall.Image.fill_path (fun ctx -> Wall.Path.circle ctx ~cx ~cy ~r:radius)
    | `Ellipse ->
        let cx = bounds.x +. (bounds.width /. 2.0) in
        let cy = bounds.y +. (bounds.height /. 2.0) in
        let rx = bounds.width /. 2.0 and ry = bounds.height /. 2.0 in
        Wall.Image.fill_path (fun ctx -> Wall.Path.ellipse ctx ~cx ~cy ~rx ~ry)
    | `Path points -> (
        match points with
        | [] ->
            Wall.Image.empty
        | (first_x, first_y) :: rest ->
            Wall.Image.fill_path (fun ctx ->
                Wall.Path.move_to ctx ~x:first_x ~y:first_y;
                List.iter (fun (x, y) -> Wall.Path.line_to ctx ~x ~y) rest))

  let render_shape_stroke bounds stroke_width = function
    | `Rectangle ->
        Wall.Image.stroke_path (Wall.Outline.make ~width:stroke_width ())
          (fun ctx ->
            Wall.Path.rect ctx ~x:bounds.x ~y:bounds.y ~w:bounds.width
              ~h:bounds.height)
    | `RoundedRectangle radius ->
        Wall.Image.stroke_path (Wall.Outline.make ~width:stroke_width ())
          (fun ctx ->
            Wall.Path.round_rect ctx ~x:bounds.x ~y:bounds.y ~w:bounds.width
              ~h:bounds.height ~r:radius)
    | `Circle ->
        let cx = bounds.x +. (bounds.width /. 2.0) in
        let cy = bounds.y +. (bounds.height /. 2.0) in
        let radius = Float.min bounds.width bounds.height /. 2.0 in
        Wall.Image.stroke_path (Wall.Outline.make ~width:stroke_width ())
          (fun ctx -> Wall.Path.circle ctx ~cx ~cy ~r:radius)
    | `Ellipse ->
        let cx = bounds.x +. (bounds.width /. 2.0) in
        let cy = bounds.y +. (bounds.height /. 2.0) in
        let rx = bounds.width /. 2.0 and ry = bounds.height /. 2.0 in
        Wall.Image.stroke_path (Wall.Outline.make ~width:stroke_width ())
          (fun ctx -> Wall.Path.ellipse ctx ~cx ~cy ~rx ~ry)
    | `Path points -> (
        match points with
        | [] ->
            Wall.Image.empty
        | (first_x, first_y) :: rest ->
            Wall.Image.stroke_path (Wall.Outline.make ~width:stroke_width ())
              (fun ctx ->
                Wall.Path.move_to ctx ~x:first_x ~y:first_y;
                List.iter (fun (x, y) -> Wall.Path.line_to ctx ~x ~y) rest))

  let render_primitive_node (node : render_primitive) =
    let bounds = node.bounds in
    match node.style with
    | RenderStyle.Fill color ->
        Wall.Image.paint (color_to_paint color)
          (render_shape_fill bounds node.shape)
    | RenderStyle.Stroke (color, stroke_width) ->
        Wall.Image.paint (color_to_paint color)
          (render_shape_stroke bounds stroke_width node.shape)
    | RenderStyle.FillAndStroke (fill_color, stroke_color, stroke_width) ->
        Wall.Image.seq
          [
            Wall.Image.paint
              (color_to_paint fill_color)
              (render_shape_fill bounds node.shape);
            Wall.Image.paint
              (color_to_paint stroke_color)
              (render_shape_stroke bounds stroke_width node.shape);
          ]
    | RenderStyle.Text (color, text, text_x, text_y, font_size) -> (
        match Lazy.force default_font with
        | None ->
            let placeholder =
              Wall.Image.fill_path (fun ctx ->
                  Wall.Path.circle ctx ~cx:(float_of_int text_x)
                    ~cy:(float_of_int text_y) ~r:8.0)
            in
            let fallback = Color.make ~r:255 ~g:0 ~b:0 () in
            Wall.Image.paint (color_to_paint fallback) placeholder
        | Some font_data ->
            let font = Wall_text.Font.make ~size:font_size font_data in
            Wall.Image.paint (color_to_paint color)
              (Wall_text.simple_text font ~x:(float_of_int text_x)
                 ~y:(float_of_int text_y) ~halign:`CENTER ~valign:`MIDDLE text))

  let render_node ~x ~y node =
    Layout.layout_node_impl ~x ~y node
    |> List.map render_primitive_node
    |> Wall.Image.seq

  let render_primitives_list primitives =
    primitives |> List.map render_primitive_node |> Wall.Image.seq

  let render_view ?(fps = 0.0) state node () =
    (* Clear screen by rendering a full-screen background *)
    let clear_background =
      Wall.Image.paint
        (Wall.Paint.color (Wall.Color.v 0.0 0.0 0.0 1.0))
        (Wall.Image.fill_path (fun ctx ->
             Wall.Path.rect ctx ~x:0.0 ~y:0.0 ~w:state.width ~h:state.height))
    in
    let scene = render_node ~x:0 ~y:0 node in
    let fps_text =
      if fps > 0.0 then
        let fps_color = Color.make ~r:0 ~g:255 ~b:0 () in
        Wall.Image.paint (color_to_paint fps_color)
          (match Lazy.force default_font with
          | None ->
              Wall.Image.empty
          | Some font_data ->
              let font = Wall_text.Font.make ~size:14.0 font_data in
              let x = state.width -. 10.0 in
              Wall_text.simple_text font ~x ~y:20.0 ~halign:`RIGHT ~valign:`TOP
                (Printf.sprintf "FPS: %.1f" fps))
      else
        Wall.Image.empty
    in
    let final_scene = Wall.Image.seq [ clear_background; scene; fps_text ] in
    Wall.Renderer.render state.wall_renderer ~width:state.width
      ~height:state.height
      ~performance_counter:(Wall.Performance_counter.make ())
      final_scene

  let render_view_with_primitives ?(fps = 0.0) state primitives () =
    (* Clear screen by rendering a full-screen background *)
    let clear_background =
      Wall.Image.paint
        (Wall.Paint.color (Wall.Color.v 0.0 0.0 0.0 1.0))
        (Wall.Image.fill_path (fun ctx ->
             Wall.Path.rect ctx ~x:0.0 ~y:0.0 ~w:state.width ~h:state.height))
    in
    let scene = render_primitives_list primitives in
    let fps_text =
      if fps > 0.0 then
        let fps_color = Color.make ~r:0 ~g:255 ~b:0 () in
        Wall.Image.paint (color_to_paint fps_color)
          (match Lazy.force default_font with
          | None ->
              Wall.Image.empty
          | Some font_data ->
              let font = Wall_text.Font.make ~size:14.0 font_data in
              let x = state.width -. 10.0 in
              Wall_text.simple_text font ~x ~y:20.0 ~halign:`RIGHT ~valign:`TOP
                (Printf.sprintf "FPS: %.1f" fps))
      else
        Wall.Image.empty
    in
    let final_scene = Wall.Image.seq [ clear_background; scene; fps_text ] in
    Wall.Renderer.render state.wall_renderer ~width:state.width
      ~height:state.height
      ~performance_counter:(Wall.Performance_counter.make ())
      final_scene
end
