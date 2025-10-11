open Mlui

module Msg = struct
  type t =
    | SetTool of Common.Tool.t
    | ColorPaletteMsg of ColorPalette.Msg.t
    | CanvasMsg of Canvas.Msg.t
end

module Model = struct
  type t = {
    selected_tool : Common.Tool.t;
    foreground : Ui.Color.t;
    background : Ui.Color.t;
    canvas_model : Canvas.Model.t;
    drawings : Common.Drawing.t list;
  }

  let init () =
    {
      selected_tool = Common.Tool.default ();
      foreground = Ui.Color.black;
      background = Ui.Color.white;
      canvas_model = Canvas.Model.init ();
      drawings = [];
    }
end

let update (msg : Msg.t) (model : Model.t) =
  match msg with
  | SetTool tool ->
      { model with selected_tool = tool }
  | ColorPaletteMsg msg -> (
      match msg with
      | ColorPalette.Msg.SetForegroundColor color ->
          { model with foreground = color }
      | ColorPalette.Msg.SetBackgroundColor color ->
          { model with background = color }
      | ColorPalette.Msg.SwapColors ->
          {
            model with
            foreground = model.background;
            background = model.foreground;
          })
  | CanvasMsg msg -> (
      let updated_canvas, out_msg = Canvas.update msg model.canvas_model in
      let model' = { model with canvas_model = updated_canvas } in
      match out_msg with
      | Some (Canvas.OutMsg.ShapeCommitted { start; eend }) ->
          let new_drawing =
            Common.Drawing.make ~start ~eend ~tool:model.selected_tool
              ~foreground:model.foreground ~background:model.background
          in
          { model' with drawings = new_drawing :: model'.drawings }
      | Some (Canvas.OutMsg.PathCommitted points) ->
          let new_drawing =
            Common.Drawing.make_path ~points ~tool:model.selected_tool
              ~foreground:model.foreground ~background:model.background
          in
          { model' with drawings = new_drawing :: model'.drawings }
      | None ->
          model')

module Styles = struct
  open Ui

  let container =
    Style.default
    |> Style.with_background Color.white
    |> Style.with_flex_direction Column

  let toolbar_and_canvas =
    Style.default
    |> Style.with_background Color.light_gray
    |> Style.with_flex_direction Row
    |> Style.with_align_items Stretch
    |> Style.with_flex_grow 1.0

  let toolbar =
    Style.default
    |> Style.with_background Color.light_gray
    |> Style.with_flex_direction Column
    |> Style.with_justify_content FlexStart
    |> Style.with_align_items Stretch
    |> Style.with_padding 10

  let toolbar_item ?(is_selected = false) () =
    Style.default
    |> Style.with_background
         (if is_selected then
            Color.gray
          else
            Color.dark_gray)
    |> Style.with_justify_content Center
    |> Style.with_align_items Center
    |> Style.with_padding 12

  let _canvas =
    Style.default
    |> Style.with_background Color.blue
    |> Style.with_justify_content Center
    |> Style.with_align_items Center
    |> Style.with_flex_grow 1.0
end

let view_tool tool (model : Model.t) =
  Ui.view
    ~style:
      (Styles.toolbar_item
         ~is_selected:(Common.Tool.is_same_family model.selected_tool tool)
         ())
    ~on_click:(fun () -> Some (Msg.SetTool tool))
    [
      Ui.text
        ~style:(Ui.Style.default |> Ui.Style.with_text_color Ui.Color.white)
        (Common.Tool.to_family_string tool);
    ]

let view_subtool tool (model : Model.t) =
  Ui.view
    ~style:(Styles.toolbar_item ~is_selected:(model.selected_tool = tool) ())
    ~on_click:(fun () -> Some (Msg.SetTool tool))
    [
      Ui.text
        ~style:(Ui.Style.default |> Ui.Style.with_text_color Ui.Color.white)
        (Common.Tool.to_string tool);
    ]

let group_in_pairs items =
  let rec loop = function
    | a :: b :: rest ->
        Ui.view
          ~style:(Ui.Style.default |> Ui.Style.with_flex_direction Row)
          [ a; b ]
        :: loop rest
    | [ a ] ->
        [
          Ui.view
            ~style:(Ui.Style.default |> Ui.Style.with_flex_direction Row)
            [ a ];
        ]
    | [] ->
        []
  in
  loop items

let view (model : Model.t) =
  Ui.view ~style:Styles.container
    [
      Ui.view ~style:Styles.toolbar_and_canvas
        [
          Ui.view
            ~style:(Ui.Style.default |> Ui.Style.with_flex_direction Column)
            [
              Common.Tool.all_family_defaults
              |> List.map (fun tool -> view_tool tool model)
              |> group_in_pairs
              |> Ui.view ~style:Styles.toolbar;
              (match Common.Tool.get_subtools model.selected_tool with
              | Some subtools ->
                  subtools
                  |> List.map (fun tool -> view_subtool tool model)
                  |> Ui.view ~style:Styles.toolbar
              | None ->
                  Ui.empty);
            ];
          Canvas.view ~init:model.canvas_model ~tool:model.selected_tool
            ~foreground:model.foreground ~background:model.background
            ~drawings:model.drawings
          |> Ui.map_msg (fun msg -> Msg.CanvasMsg msg);
        ];
      ColorPalette.view ~foreground:model.foreground
        ~background:model.background
      |> Ui.map_msg (fun msg -> Msg.ColorPaletteMsg msg);
    ]

let () =
  let window = Ui.Window.make ~width:800 ~height:600 () in
  match
    Ui.run ~window
      ~init:(Model.init ()) ~update ~view ()
  with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
