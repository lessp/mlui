type renderer_state =
  { wall_renderer : Wall.Renderer.t
  ; width : float
  ; height : float
  }

let create_renderer ~width ~height =
  let wall_renderer = Wall.Renderer.create ~antialias:true () in
  { wall_renderer; width = float_of_int width; height = float_of_int height }
;;

let color_to_paint (color : Color.t) =
  Wall.Paint.rgba
    (float_of_int color.r /. 255.0)
    (float_of_int color.g /. 255.0)
    (float_of_int color.b /. 255.0)
    (float_of_int color.a /. 255.0)
;;

let create_shape_image shape =
  match shape with
  | Shape.Rectangle { position; size } ->
    Wall.Image.fill_path (fun ctx ->
      Wall.Path.rect
        ctx
        ~x:(float_of_int position.x)
        ~y:(float_of_int position.y)
        ~w:(float_of_int size.width)
        ~h:(float_of_int size.height))
  | Shape.Ellipsis { position; size } ->
    let cx = float_of_int position.x +. (float_of_int size.width /. 2.0) in
    let cy = float_of_int position.y +. (float_of_int size.height /. 2.0) in
    let rx = float_of_int size.width /. 2.0 in
    let ry = float_of_int size.height /. 2.0 in
    Wall.Image.fill_path (fun ctx -> Wall.Path.ellipse ctx ~cx ~cy ~rx ~ry)
;;

let render_toolbar_element (shape, style) =
  let base_image = create_shape_image shape in
  match style with
  | `Background -> Wall.Image.paint (color_to_paint Color.light_gray) base_image
  | `Foreground -> Wall.Image.paint (color_to_paint Color.black) base_image
  | `BackgroundSwatch -> Wall.Image.paint (color_to_paint Color.white) base_image
  | `Selected -> Wall.Image.paint (color_to_paint Color.blue) base_image
  | `Hovered -> Wall.Image.paint (color_to_paint Color.light_blue) base_image
  | `Normal -> Wall.Image.paint (color_to_paint Color.gray) base_image

let render_model state model =
  let current_swatch = App.Model.get_current_swatch model in

  (* Create background *)
  let background =
    Wall.Image.paint
      (color_to_paint current_swatch.ColorSwatch.background)
      (Wall.Image.fill_path (fun ctx ->
         Wall.Path.rect ctx ~x:0.0 ~y:0.0 ~w:state.width ~h:state.height))
  in

  (* Create completed shape images *)
  let completed_images = List.map create_shape_image model.App.Model.completed_shapes in
  let colored_completed =
    List.map
      (Wall.Image.paint (color_to_paint current_swatch.ColorSwatch.foreground))
      completed_images
  in

  (* Create preview shape image if it exists *)
  let preview_images =
    match model.App.Model.preview_shape with
    | None -> []
    | Some shape ->
      let preview_image = create_shape_image shape in
      [ Wall.Image.paint
          (color_to_paint current_swatch.ColorSwatch.foreground)
          preview_image
      ]
  in

  (* Create toolbar images *)
  let toolbar_elements = Toolbar.view model.App.Model.toolbar in
  let toolbar_images = List.map render_toolbar_element toolbar_elements in

  (* Compose final scene *)
  let all_images = (background :: colored_completed) @ preview_images @ toolbar_images in
  let scene = Wall.Image.seq all_images in

  (* Render *)
  scene |> Wall.Renderer.render state.wall_renderer ~width:state.width ~height:state.height
;;
