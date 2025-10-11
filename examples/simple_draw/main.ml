open Mlui

module Msg = struct
  type t =
    | StartDrawing of int * int
    | ContinueDrawing of int * int
    | StopDrawing
    | Clear
    | ChangeColor of Color.t
    | ChangeSize of [ `Small | `Medium | `Large ]
end

module Model = struct
  type drawing_state = Idle | Drawing of (int * int) list

  type t = {
    state : drawing_state;
    paths : (Color.t * float * (int * int) list) list;
    current_color : Color.t;
    current_size : float;
  }

  let init () =
    {
      state = Idle;
      paths = [];
      current_color = Color.black;
      current_size = 2.0;
    }
end

let update msg model =
  match msg with
  | Msg.StartDrawing (x, y) ->
      ({ model with Model.state = Drawing [ (x, y) ] }, Cmd.none)
  | Msg.ContinueDrawing (x, y) -> (
      match model.state with
      | Drawing points ->
          ({ model with state = Drawing ((x, y) :: points) }, Cmd.none)
      | Idle ->
          (model, Cmd.none))
  | Msg.StopDrawing -> (
      match model.state with
      | Drawing points when List.length points > 1 ->
          let path =
            (model.current_color, model.current_size, List.rev points)
          in
          ({ model with state = Idle; paths = path :: model.paths }, Cmd.none)
      | _ ->
          ({ model with state = Idle }, Cmd.none))
  | Msg.Clear ->
      ({ model with paths = []; state = Idle }, Cmd.none)
  | Msg.ChangeColor color ->
      ({ model with current_color = color }, Cmd.none)
  | Msg.ChangeSize size ->
      let size_value =
        match size with `Small -> 1.0 | `Medium -> 3.0 | `Large -> 5.0
      in
      ({ model with current_size = size_value }, Cmd.none)

module Styles = struct
  let app =
    Style.default
    |> Style.with_size ~width:800 ~height:600
    |> Style.with_flex_direction Column
    |> Style.with_background Color.light_gray

  let toolbar =
    Style.default
    |> Style.with_flex_direction Row
    |> Style.with_padding 10
    |> Style.with_background Color.gray

  let canvas =
    Style.default
    |> Style.with_flex_grow 1.0
    |> Style.with_background Color.white

  let primary_button =
    Style.default
    |> Style.with_size ~width:80 ~height:30
    |> Style.with_background Color.blue
    |> Style.with_justify_content Center
    |> Style.with_align_items Center

  let color_option color =
    Style.default
    |> Style.with_size ~width:30 ~height:30
    |> Style.with_background color

  let size_button =
    Style.default
    |> Style.with_size ~width:50 ~height:30
    |> Style.with_background Color.dark_gray
    |> Style.with_justify_content Center
    |> Style.with_align_items Center

  let button_text =
    Style.default
    |> Style.with_text_color Color.white
    |> Style.with_font_size 14.0
end

let view (model : Model.t) : Msg.t Mlui.node =
  (* Create canvas primitives from paths *)
  let path_to_primitive (color, width, points) =
    match points with
    | [] ->
        None
    | _ ->
        let float_points =
          List.map (fun (x, y) -> (float_of_int x, float_of_int y)) points
        in
        Some (path ~points:float_points ~style:(stroke color width))
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
    view ~style:Styles.primary_button
      ~on_click:(fun () -> Some Msg.Clear)
      [ text ~style:Styles.button_text "Clear" ]
  in

  let colors =
    [
      Color.black;
      Color.red;
      Color.make ~r:0 ~g:255 ~b:0 ();
      Color.blue;
      Color.yellow;
      Color.magenta;
      Color.cyan;
    ]
  in

  let color_buttons =
    colors
    |> List.map (fun color ->
           view
             ~style:(Styles.color_option color)
             ~on_click:(fun () -> Some (Msg.ChangeColor color))
             [])
  in

  let size_buttons =
    [ (`Small, "S"); (`Medium, "M"); (`Large, "L") ]
    |> List.map (fun (size, label) ->
           view ~style:Styles.size_button
             ~on_click:(fun () -> Some (Msg.ChangeSize size))
             [ text ~style:Styles.button_text label ])
  in

  let toolbar =
    view ~style:Styles.toolbar
      ([ clear_button ] @ color_buttons @ size_buttons)
  in

  (* Create canvas with event handlers *)
  let canvas =
    canvas ~style:Styles.canvas
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
  view ~style:Styles.app [ toolbar; canvas ]

(* Main function *)
let () =
  let window = Window.make ~width:800 ~height:600 () in

  match
    Mlui.run ~window ~init:(Model.init ()) ~update ~view ()
  with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
