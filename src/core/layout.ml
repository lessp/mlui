open Types

(* Reference flex types from Style module *)
open Style

module FlexIntegration = struct
  module UINode = struct
    type context = unit

    let nullContext = ()
  end

  module UIEncoding = struct
    include Flex.FixedEncoding
  end

  module FlexLayoutEngine = Flex.Layout.Create (UINode) (UIEncoding)
  module FlexLayoutSupport = FlexLayoutEngine.LayoutSupport
  module FlexTypes = FlexLayoutSupport.LayoutTypes

  let ui_flex_direction_to_flex = function
    | Row ->
        FlexTypes.Row
    | Column ->
        FlexTypes.Column
    | RowReverse ->
        FlexTypes.RowReverse
    | ColumnReverse ->
        FlexTypes.ColumnReverse

  let ui_justify_content_to_flex = function
    | FlexStart ->
        FlexTypes.JustifyFlexStart
    | Center ->
        FlexTypes.JustifyCenter
    | FlexEnd ->
        FlexTypes.JustifyFlexEnd
    | SpaceBetween ->
        FlexTypes.JustifySpaceBetween
    | SpaceAround ->
        FlexTypes.JustifySpaceAround

  let ui_align_items_to_flex = function
    | Stretch ->
        FlexTypes.AlignStretch
    | Start ->
        FlexTypes.AlignFlexStart
    | Center ->
        FlexTypes.AlignCenter
    | End ->
        FlexTypes.AlignFlexEnd
end

module FlexIntegrationImpl = struct
  include FlexIntegration

  let style_to_flex_style (style : Style.t) : FlexTypes.cssStyle =
    let open FlexTypes in
    {
      FlexLayoutEngine.LayoutSupport.defaultStyle with
      flexDirection =
        (match style.flex_direction with
        | Some dir ->
            ui_flex_direction_to_flex dir
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.flexDirection);
      justifyContent =
        (match style.justify_content with
        | Some justify ->
            ui_justify_content_to_flex justify
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.justifyContent);
      alignItems =
        (match style.align_items with
        | Some align ->
            ui_align_items_to_flex align
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.alignItems);
      flexGrow =
        (match style.flex_grow with
        | Some grow ->
            int_of_float grow
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.flexGrow);
      flexShrink =
        (match style.flex_shrink with
        | Some shrink ->
            int_of_float shrink
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.flexShrink);
      flexBasis =
        (match style.flex_basis with
        | Some basis ->
            int_of_float basis
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.flexBasis);
      width =
        (match style.width with
        | Some w ->
            w
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.width);
      height =
        (match style.height with
        | Some h ->
            h
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.height);
      left =
        (match style.position_x with
        | Some x ->
            x
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.left);
      top =
        (match style.position_y with
        | Some y ->
            y
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.top);
      paddingLeft =
        (match style.padding with
        | Some p ->
            p
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.paddingLeft);
      paddingTop =
        (match style.padding with
        | Some p ->
            p
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.paddingTop);
      paddingRight =
        (match style.padding with
        | Some p ->
            p
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.paddingRight);
      paddingBottom =
        (match style.padding with
        | Some p ->
            p
        | None ->
            FlexLayoutEngine.LayoutSupport.defaultStyle.paddingBottom);
    }

  let is_absolutely_positioned ui_node =
    match ui_node with
    | View { style; _ } | Text { style; _ } | Canvas { style; _ } ->
        style.position_type = Some Absolute
    | Empty ->
        false

  let rec create_flex_node (ui_node : 'msg interactive_node) : FlexTypes.node =
    match ui_node with
    | Empty ->
        FlexLayoutSupport.createNode ~withChildren:[||]
          ~andStyle:(style_to_flex_style Style.default)
          ()
    | Text { style; _ } | Canvas { style; _ } ->
        FlexLayoutSupport.createNode ~withChildren:[||]
          ~andStyle:(style_to_flex_style style)
          ()
    | View { style; children; _ } ->
        (* Filter out absolutely positioned children *)
        let relative_children =
          List.filter
            (fun child -> not (is_absolutely_positioned child))
            children
        in
        let flex_children =
          Array.of_list (List.map create_flex_node relative_children)
        in
        FlexLayoutSupport.createNode ~withChildren:flex_children
          ~andStyle:(style_to_flex_style style)
          ()

  let get_layout_info (node : FlexTypes.node) : bounds =
    let open FlexTypes in
    let layout = node.layout in
    {
      x = UIEncoding.scalarToFloat layout.left *. 100.0;
      y = UIEncoding.scalarToFloat layout.top *. 100.0;
      width = UIEncoding.scalarToFloat layout.width *. 100.0;
      height = UIEncoding.scalarToFloat layout.height *. 100.0;
    }

  let get_transform_offset transform_opt =
    match transform_opt with
    | Some (Translate { x; y }) ->
        (x, y)
    | Some (TranslateX x) ->
        (x, 0.0)
    | Some (TranslateY y) ->
        (0.0, y)
    | Some (Compose transforms) ->
        List.fold_left
          (fun (acc_x, acc_y) t ->
            match t with
            | Translate { x; y } ->
                (acc_x +. x, acc_y +. y)
            | TranslateX x ->
                (acc_x +. x, acc_y)
            | TranslateY y ->
                (acc_x, acc_y +. y)
            | _ ->
                (acc_x, acc_y))
          (0.0, 0.0) transforms
    | _ ->
        (0.0, 0.0)

  let rec apply_layout_to_ui_node ?(offset_x = 0.0) ?(offset_y = 0.0)
      (flex_node : FlexTypes.node) (ui_node : 'msg interactive_node) :
      render_primitive list =
    let layout_bounds = get_layout_info flex_node in

    (* Get style and apply transform *)
    let style =
      match ui_node with
      | View { style; _ } ->
          style
      | Text { style; _ } ->
          style
      | Canvas { style; _ } ->
          style
      | Empty ->
          Style.default
    in

    let transform_x, transform_y = get_transform_offset style.transform in
    let abs_x = offset_x +. layout_bounds.x +. transform_x in
    let abs_y = offset_y +. layout_bounds.y +. transform_y in
    match ui_node with
    | Empty ->
        []
    | Text { content; style; _ } ->
        let font_size = Option.value style.font_size ~default:12.0 in
        let text_color =
          Option.value style.text_color ~default:(Color.make ~r:0 ~g:0 ~b:0 ())
        in
        [
          {
            bounds =
              {
                x = abs_x;
                y = abs_y;
                width = layout_bounds.width;
                height = layout_bounds.height;
              };
            shape = `Rectangle;
            style =
              RenderStyle.Text
                ( text_color,
                  content,
                  int_of_float abs_x,
                  int_of_float abs_y,
                  font_size );
          };
        ]
    | Canvas { primitives; style; _ } ->
        let background =
          match style.background_color with
          | None ->
              []
          | Some bg_color ->
              let bg_style =
                match (style.border_color, style.border_width) with
                | Some border_color, Some border_width ->
                    RenderStyle.FillAndStroke
                      (bg_color, border_color, border_width)
                | _ ->
                    RenderStyle.Fill bg_color
              in
              [
                {
                  bounds =
                    {
                      x = abs_x;
                      y = abs_y;
                      width = layout_bounds.width;
                      height = layout_bounds.height;
                    };
                  shape =
                    (match style.border_radius with
                    | Some radius ->
                        `RoundedRectangle radius
                    | None ->
                        `Rectangle);
                  style = bg_style;
                };
              ]
        in
        let converted_primitives =
          primitives
          |> List.map (fun primitive ->
                 match primitive with
                 | Rectangle { x; y; width; height; style } ->
                     let render_style =
                       match style with
                       | Fill color ->
                           RenderStyle.Fill color
                       | Stroke (color, w) ->
                           RenderStyle.Stroke (color, w)
                       | FillAndStroke (fill, stroke, w) ->
                           RenderStyle.FillAndStroke (fill, stroke, w)
                     in
                     {
                       bounds =
                         { x = x +. abs_x; y = y +. abs_y; width; height };
                       shape = `Rectangle;
                       style = render_style;
                     }
                 | Ellipse { cx; cy; rx; ry; style } ->
                     let render_style =
                       match style with
                       | Fill color ->
                           RenderStyle.Fill color
                       | Stroke (color, w) ->
                           RenderStyle.Stroke (color, w)
                       | FillAndStroke (fill, stroke, w) ->
                           RenderStyle.FillAndStroke (fill, stroke, w)
                     in
                     let bounds_x = cx -. rx +. abs_x in
                     let bounds_y = cy -. ry +. abs_y in
                     let bounds_width = rx *. 2.0 in
                     let bounds_height = ry *. 2.0 in
                     {
                       bounds =
                         {
                           x = bounds_x;
                           y = bounds_y;
                           width = bounds_width;
                           height = bounds_height;
                         };
                       shape = `Ellipse;
                       style = render_style;
                     }
                 | Path { points; style } ->
                     let render_style =
                       match style with
                       | Fill color ->
                           RenderStyle.Fill color
                       | Stroke (color, w) ->
                           RenderStyle.Stroke (color, w)
                       | FillAndStroke (fill, stroke, w) ->
                           RenderStyle.FillAndStroke (fill, stroke, w)
                     in
                     let offset_points =
                       List.map
                         (fun (px, py) -> (px +. abs_x, py +. abs_y))
                         points
                     in
                     let bounds =
                       match offset_points with
                       | [] ->
                           { x = abs_x; y = abs_y; width = 0.0; height = 0.0 }
                       | _ ->
                           let xs = List.map fst offset_points in
                           let ys = List.map snd offset_points in
                           let min_x = List.fold_left min (List.hd xs) xs in
                           let max_x = List.fold_left max (List.hd xs) xs in
                           let min_y = List.fold_left min (List.hd ys) ys in
                           let max_y = List.fold_left max (List.hd ys) ys in
                           {
                             x = min_x;
                             y = min_y;
                             width = max_x -. min_x;
                             height = max_y -. min_y;
                           }
                     in
                     {
                       bounds;
                       shape = `Path offset_points;
                       style = render_style;
                     })
        in
        background @ converted_primitives
    | View { style; children; _ } ->
        let background =
          match style.background_color with
          | None ->
              []
          | Some bg_color ->
              let bg_style =
                match (style.border_color, style.border_width) with
                | Some border_color, Some border_width ->
                    RenderStyle.FillAndStroke
                      (bg_color, border_color, border_width)
                | _ ->
                    RenderStyle.Fill bg_color
              in
              [
                {
                  bounds =
                    {
                      x = abs_x;
                      y = abs_y;
                      width = layout_bounds.width;
                      height = layout_bounds.height;
                    };
                  shape =
                    (match style.border_radius with
                    | Some radius ->
                        `RoundedRectangle radius
                    | None ->
                        `Rectangle);
                  style = bg_style;
                };
              ]
        in
        let relative_children =
          List.filter
            (fun child -> not (is_absolutely_positioned child))
            children
        in
        let absolute_children = List.filter is_absolutely_positioned children in

        (* Render relative children using flex layout *)
        let relative_primitives =
          List.mapi
            (fun i child ->
              if i < Array.length flex_node.children then
                apply_layout_to_ui_node ~offset_x:abs_x ~offset_y:abs_y
                  flex_node.children.(i) child
              else
                [])
            relative_children
          |> List.concat
        in

        (* Render absolute children positioned at parent origin *)
        let absolute_primitives =
          List.concat_map
            (fun child ->
              let child_style =
                match child with
                | View { style; _ } ->
                    style
                | Text { style; _ } ->
                    style
                | Canvas { style; _ } ->
                    style
                | Empty ->
                    Style.default
              in
              let transform_x, transform_y =
                get_transform_offset child_style.transform
              in
              apply_layout_to_ui_node_absolute ~offset_x:(abs_x +. transform_x)
                ~offset_y:(abs_y +. transform_y) child child_style)
            absolute_children
        in

        background @ relative_primitives @ absolute_primitives

  and apply_layout_to_ui_node_absolute ~offset_x ~offset_y
      (ui_node : 'msg interactive_node) (style : Style.t) :
      render_primitive list =
    (* For absolutely positioned elements, render without flex layout *)
    let width = Option.value style.width ~default:0 in
    let height = Option.value style.height ~default:0 in
    let bounds =
      {
        x = offset_x;
        y = offset_y;
        width = float_of_int width;
        height = float_of_int height;
      }
    in

    match ui_node with
    | Empty ->
        []
    | Text { content; style; _ } ->
        let font_size = Option.value style.font_size ~default:12.0 in
        let text_color =
          Option.value style.text_color ~default:(Color.make ~r:0 ~g:0 ~b:0 ())
        in
        [
          {
            bounds;
            shape = `Rectangle;
            style =
              RenderStyle.Text
                ( text_color,
                  content,
                  int_of_float offset_x,
                  int_of_float offset_y,
                  font_size );
          };
        ]
    | Canvas { primitives; style; _ } ->
        let background =
          match style.background_color with
          | None ->
              []
          | Some bg_color ->
              let bg_style =
                match (style.border_color, style.border_width) with
                | Some border_color, Some border_width ->
                    RenderStyle.FillAndStroke
                      (bg_color, border_color, border_width)
                | _ ->
                    RenderStyle.Fill bg_color
              in
              [
                {
                  bounds;
                  shape =
                    (match style.border_radius with
                    | Some radius ->
                        `RoundedRectangle radius
                    | None ->
                        `Rectangle);
                  style = bg_style;
                };
              ]
        in
        let converted_primitives =
          primitives
          |> List.map (fun primitive ->
                 match primitive with
                 | Rectangle { x; y; width; height; style } ->
                     let render_style =
                       match style with
                       | Fill color ->
                           RenderStyle.Fill color
                       | Stroke (color, w) ->
                           RenderStyle.Stroke (color, w)
                       | FillAndStroke (fill, stroke, w) ->
                           RenderStyle.FillAndStroke (fill, stroke, w)
                     in
                     {
                       bounds =
                         { x = offset_x +. x; y = offset_y +. y; width; height };
                       shape = `Rectangle;
                       style = render_style;
                     }
                 | Ellipse { cx; cy; rx; ry; style } ->
                     let render_style =
                       match style with
                       | Fill color ->
                           RenderStyle.Fill color
                       | Stroke (color, w) ->
                           RenderStyle.Stroke (color, w)
                       | FillAndStroke (fill, stroke, w) ->
                           RenderStyle.FillAndStroke (fill, stroke, w)
                     in
                     {
                       bounds =
                         {
                           x = offset_x +. cx -. rx;
                           y = offset_y +. cy -. ry;
                           width = rx *. 2.0;
                           height = ry *. 2.0;
                         };
                       shape = `Ellipse;
                       style = render_style;
                     }
                 | Path { points; style } ->
                     let render_style =
                       match style with
                       | Fill color ->
                           RenderStyle.Fill color
                       | Stroke (color, w) ->
                           RenderStyle.Stroke (color, w)
                       | FillAndStroke (fill, stroke, w) ->
                           RenderStyle.FillAndStroke (fill, stroke, w)
                     in
                     let offset_points =
                       List.map
                         (fun (px, py) -> (px +. offset_x, py +. offset_y))
                         points
                     in
                     let bounds =
                       match offset_points with
                       | [] ->
                           {
                             x = offset_x;
                             y = offset_y;
                             width = 0.0;
                             height = 0.0;
                           }
                       | _ ->
                           let xs = List.map fst offset_points in
                           let ys = List.map snd offset_points in
                           let min_x = List.fold_left min (List.hd xs) xs in
                           let max_x = List.fold_left max (List.hd xs) xs in
                           let min_y = List.fold_left min (List.hd ys) ys in
                           let max_y = List.fold_left max (List.hd ys) ys in
                           {
                             x = min_x;
                             y = min_y;
                             width = max_x -. min_x;
                             height = max_y -. min_y;
                           }
                     in
                     {
                       bounds;
                       shape = `Path offset_points;
                       style = render_style;
                     })
        in
        background @ converted_primitives
    | View { style; children; _ } ->
        let background =
          match style.background_color with
          | None ->
              []
          | Some bg_color ->
              let bg_style =
                match (style.border_color, style.border_width) with
                | Some border_color, Some border_width ->
                    RenderStyle.FillAndStroke
                      (bg_color, border_color, border_width)
                | _ ->
                    RenderStyle.Fill bg_color
              in
              [
                {
                  bounds;
                  shape =
                    (match style.border_radius with
                    | Some radius ->
                        `RoundedRectangle radius
                    | None ->
                        `Rectangle);
                  style = bg_style;
                };
              ]
        in
        let child_primitives =
          List.concat_map
            (fun child ->
              let child_style =
                match child with
                | View { style; _ } ->
                    style
                | Text { style; _ } ->
                    style
                | Canvas { style; _ } ->
                    style
                | Empty ->
                    Style.default
              in
              let transform_x, transform_y =
                get_transform_offset child_style.transform
              in
              apply_layout_to_ui_node_absolute
                ~offset_x:(offset_x +. transform_x)
                ~offset_y:(offset_y +. transform_y) child child_style)
            children
        in
        background @ child_primitives

  let layout_ui_tree ?(width = 800) ?(height = 600)
      (ui_root : 'msg interactive_node) : render_primitive list =
    let flex_root = create_flex_node ui_root in
    FlexLayoutEngine.layoutNode flex_root width height FlexTypes.Ltr;
    apply_layout_to_ui_node flex_root ui_root

  let rec build_node_with_bounds ?(offset_x = 0.0) ?(offset_y = 0.0)
      ?(path = []) (flex_node : FlexTypes.node)
      (ui_node : 'msg interactive_node) : 'msg node_with_bounds =
    let layout_bounds = get_layout_info flex_node in
    let abs_x = offset_x +. layout_bounds.x in
    let abs_y = offset_y +. layout_bounds.y in

    (* Apply transform if present *)
    let style =
      match ui_node with
      | View { style; _ } ->
          style
      | Text { style; _ } ->
          style
      | Canvas { style; _ } ->
          style
      | Empty ->
          Style.default
    in

    let transform_x, transform_y =
      match style.transform with
      | Some (Translate { x; y }) ->
          (x, y)
      | Some (TranslateX x) ->
          (x, 0.0)
      | Some (TranslateY y) ->
          (0.0, y)
      | Some (Compose transforms) ->
          (* For now, just accumulate translations from composed transforms *)
          List.fold_left
            (fun (acc_x, acc_y) t ->
              match t with
              | Translate { x; y } ->
                  (acc_x +. x, acc_y +. y)
              | TranslateX x ->
                  (acc_x +. x, acc_y)
              | TranslateY y ->
                  (acc_x, acc_y +. y)
              | _ ->
                  (acc_x, acc_y))
            (0.0, 0.0) transforms
      | _ ->
          (0.0, 0.0)
    in

    let bounds =
      {
        x = abs_x +. transform_x;
        y = abs_y +. transform_y;
        width = layout_bounds.width;
        height = layout_bounds.height;
      }
    in
    let children =
      match ui_node with
      | View { children = ui_children; _ } ->
          let relative_children =
            List.filter
              (fun child -> not (is_absolutely_positioned child))
              ui_children
          in
          let absolute_children =
            List.filter is_absolutely_positioned ui_children
          in

          (* Process relative children using flex layout *)
          (* let () = Printf.eprintf "relative_children count: %d, flex_node.children count: %d\n%!"
            (List.length relative_children) (Array.length flex_node.children) in *)
          let relative_bounds =
            List.mapi
              (fun i child ->
                if i < Array.length flex_node.children then
                  build_node_with_bounds ~offset_x:abs_x ~offset_y:abs_y
                    ~path:(path @ [ i ]) flex_node.children.(i) child
                else
                  let () =
                    Printf.eprintf "WARNING: child %d out of bounds!\n%!" i
                  in
                  {
                    node = child;
                    bounds = { x = 0.0; y = 0.0; width = 0.0; height = 0.0 };
                    children = [];
                    path = path @ [ i ];
                  })
              relative_children
          in

          (* Process absolute children - position at parent origin (0,0) *)
          let absolute_bounds =
            List.mapi
              (fun i child ->
                let child_style =
                  match child with
                  | View { style; _ } ->
                      style
                  | Text { style; _ } ->
                      style
                  | Canvas { style; _ } ->
                      style
                  | Empty ->
                      Style.default
                in
                let width = Option.value child_style.width ~default:0 in
                let height = Option.value child_style.height ~default:0 in
                let transform_x, transform_y =
                  get_transform_offset child_style.transform
                in
                {
                  node = child;
                  bounds =
                    {
                      x = abs_x +. transform_x;
                      y = abs_y +. transform_y;
                      width = float_of_int width;
                      height = float_of_int height;
                    };
                  children = [];
                  path = path @ [ List.length relative_children + i ];
                })
              absolute_children
          in

          relative_bounds @ absolute_bounds
      | _ ->
          []
    in
    { node = ui_node; bounds; children; path }
end

let layout_node_impl ~x:_ ~y:_ node = FlexIntegrationImpl.layout_ui_tree node

let layout_with_bounds ?(width = 800) ?(height = 600) node =
  let flex_root = FlexIntegrationImpl.create_flex_node node in
  FlexIntegrationImpl.FlexLayoutEngine.layoutNode flex_root width height
    FlexIntegrationImpl.FlexTypes.Ltr;
  FlexIntegrationImpl.build_node_with_bounds flex_root node

let layout_with_bounds_and_primitives ?(width = 800) ?(height = 600) node =
  let flex_root = FlexIntegrationImpl.create_flex_node node in
  FlexIntegrationImpl.FlexLayoutEngine.layoutNode flex_root width height
    FlexIntegrationImpl.FlexTypes.Ltr;
  let bounds_tree = FlexIntegrationImpl.build_node_with_bounds flex_root node in
  let primitives = FlexIntegrationImpl.apply_layout_to_ui_node flex_root node in
  (bounds_tree, primitives)
