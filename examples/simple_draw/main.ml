open Mlui

module Msg = struct
  type t =
    | StartDrawing of int * int
    | ContinueDrawing of int * int
    | StopDrawing
    | Clear
    | ChangeColor of Ui.Color.t
    | ChangeSize of [ `Small | `Medium | `Large ]
end

module Model = struct
  type drawing_state = Idle | Drawing of (int * int) list

  type t = {
    state : drawing_state;
    paths : (Ui.Color.t * float * (int * int) list) list;
    current_color : Ui.Color.t;
    current_size : float;
  }

  let init () =
    {
      state = Idle;
      paths = [];
      current_color = Ui.Color.black;
      current_size = 2.0;
    }
end

let update msg model =
  match msg with
  | Msg.StartDrawing (x, y) ->
      { model with Model.state = Drawing [ (x, y) ] }
  | Msg.ContinueDrawing (x, y) -> (
      match model.state with
      | Drawing points ->
          { model with state = Drawing ((x, y) :: points) }
      | Idle ->
          model)
  | Msg.StopDrawing -> (
      match model.state with
      | Drawing points when List.length points > 1 ->
          let path =
            (model.current_color, model.current_size, List.rev points)
          in
          { model with state = Idle; paths = path :: model.paths }
      | _ ->
          { model with state = Idle })
  | Msg.Clear ->
      { model with paths = []; state = Idle }
  | Msg.ChangeColor color ->
      { model with current_color = color }
  | Msg.ChangeSize size ->
      let size_value =
        match size with `Small -> 1.0 | `Medium -> 3.0 | `Large -> 5.0
      in
      { model with current_size = size_value }

module Styles = struct
  let app =
    Ui.Style.default
    |> Ui.Style.with_size ~width:800 ~height:600
    |> Ui.Style.with_flex_direction Column
    |> Ui.Style.with_background Ui.Color.light_gray

  let toolbar =
    Ui.Style.default
    |> Ui.Style.with_flex_direction Row
    |> Ui.Style.with_padding 10
    |> Ui.Style.with_background Ui.Color.gray

  let canvas =
    Ui.Style.default
    |> Ui.Style.with_flex_grow 1.0
    |> Ui.Style.with_background Ui.Color.white

  let primary_button =
    Ui.Style.default
    |> Ui.Style.with_size ~width:80 ~height:30
    |> Ui.Style.with_background Ui.Color.blue
    |> Ui.Style.with_justify_content Center
    |> Ui.Style.with_align_items Center

  let color_option color =
    Ui.Style.default
    |> Ui.Style.with_size ~width:30 ~height:30
    |> Ui.Style.with_background color

  let size_button =
    Ui.Style.default
    |> Ui.Style.with_size ~width:50 ~height:30
    |> Ui.Style.with_background Ui.Color.dark_gray
    |> Ui.Style.with_justify_content Center
    |> Ui.Style.with_align_items Center

  let button_text =
    Ui.Style.default
    |> Ui.Style.with_text_color Ui.Color.white
    |> Ui.Style.with_font_size 14.0
end

let view (model : Model.t) : Msg.t Ui.node =
  (* Create canvas primitives from paths *)
  let path_to_primitive (color, width, points) =
    match points with
    | [] ->
        None
    | _ ->
        let float_points =
          List.map (fun (x, y) -> (float_of_int x, float_of_int y)) points
        in
        Some (Ui.path ~points:float_points ~style:(Ui.stroke color width))
  in

  (* Add current drawing path if drawing *)
  let current_path_primitive =
    match model.state with
    | Model.Drawing points when List.length points > 1 ->
        path_to_primitive
          (model.current_color, model.current_size, List.rev points)
    | _ ->
        None
  in

  let all_primitives =
    let path_primitives =
      model.paths |> List.filter_map path_to_primitive |> List.rev
    in
    match current_path_primitive with
    | Some p ->
        path_primitives @ [ p ]
    | None ->
        path_primitives
  in

  (* Create toolbar *)
  let clear_button =
    Ui.view ~style:Styles.primary_button
      ~on_click:(fun () -> Some Msg.Clear)
      [ Ui.text ~style:Styles.button_text "Clear" ]
  in

  let colors =
    [
      Ui.Color.black;
      Ui.Color.red;
      Ui.Color.make ~r:0 ~g:255 ~b:0 ();
      Ui.Color.blue;
      Ui.Color.yellow;
      Ui.Color.magenta;
      Ui.Color.cyan;
    ]
  in

  let color_buttons =
    colors
    |> List.map (fun color ->
           Ui.view
             ~style:(Styles.color_option color)
             ~on_click:(fun () -> Some (Msg.ChangeColor color))
             [])
  in

  let size_buttons =
    [ (`Small, "S"); (`Medium, "M"); (`Large, "L") ]
    |> List.map (fun (size, label) ->
           Ui.view ~style:Styles.size_button
             ~on_click:(fun () -> Some (Msg.ChangeSize size))
             [ Ui.text ~style:Styles.button_text label ])
  in

  let toolbar =
    Ui.view ~style:Styles.toolbar
      ([ clear_button ] @ color_buttons @ size_buttons)
  in

  (* Create canvas with event handlers *)
  let canvas =
    Ui.canvas ~style:Styles.canvas
      ~on_mouse_down:(fun (x, y) -> Some (Msg.StartDrawing (x, y)))
      ~on_mouse_move:(fun (x, y) ->
        match model.state with
        | Drawing _ ->
            Some (Msg.ContinueDrawing (x, y))
        | Idle ->
            None)
      ~on_mouse_up:(fun _ -> Some Msg.StopDrawing)
      all_primitives
  in

  (* Main app layout *)
  Ui.view ~style:Styles.app [ toolbar; canvas ]

(* Main function *)
let () =
  let window = Ui.Window.make ~width:800 ~height:600 () in

  match
    Ui.run ~window ~init:(Model.init ()) ~update ~view ()
  with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
