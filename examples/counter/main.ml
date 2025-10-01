open Mlui

type button = Increment | Decrement | Reset

module Msg = struct
  type t =
    | Increment
    | Decrement
    | Reset
    | SetColor of Ui.Color.t
    | SetHover of button option
end

module Model = struct
  type t = { counter : int; bg_color : Ui.Color.t; hovered : button option }

  let init () = { counter = 0; bg_color = Ui.Color.gray; hovered = None }
end

let lighten_color (color : Ui.Color.t) delta : Ui.Color.t =
  let open Ui.Color in
  let clamp v = max 0 (min 255 v) in
  let { r; g; b; a } = color in
  { r = clamp (r + delta); g = clamp (g + delta); b = clamp (b + delta); a }

let update msg (model : Model.t) =
  match msg with
  | Msg.Increment ->
      { model with Model.counter = model.counter + 1 }
  | Msg.Decrement ->
      { model with Model.counter = model.counter - 1 }
  | Msg.Reset ->
      { model with Model.counter = 0 }
  | Msg.SetColor color ->
      { model with Model.bg_color = color }
  | Msg.SetHover hovered ->
      { model with Model.hovered }

module Styles = struct
  open Ui

  let container background =
    Style.default |> Style.with_flex_grow 1.0
    |> Style.with_flex_direction Column
    |> Style.with_justify_content Center
    |> Style.with_align_items Center
    |> Style.with_background background
    |> Style.with_padding 20

  let counter_text =
    Style.default
    |> Style.with_text_color Color.black
    |> Style.with_font_size 32.0 |> Style.with_padding 20

  let button ~hovered base_color =
    Style.default |> Style.with_padding 15
    |> Style.with_background
         (if hovered then
            lighten_color base_color 40
          else
            base_color)
    |> Style.with_justify_content Center
    |> Style.with_align_items Center

  let button_row =
    Style.default |> Style.with_flex_direction Row |> Style.with_padding 10

  let spacer = Style.default |> Style.with_padding 5

  let palette_row =
    Style.default |> Style.with_flex_direction Row |> Style.with_padding 20

  let palette_option color =
    Style.default |> Style.with_padding 20 |> Style.with_background color
end

let view (model : Model.t) : Msg.t Ui.node =
  let hovered button =
    match model.hovered with Some btn when btn = button -> true | _ -> false
  in

  Ui.view
    ~style:(Styles.container model.bg_color)
    [
      Ui.text ~style:Styles.counter_text
        (Printf.sprintf "Count: %d" model.counter);
      Ui.view ~style:Styles.button_row
        [
          Ui.view
            ~style:
              (Styles.button ~hovered:(hovered Decrement)
                 (Ui.Color.make ~r:100 ~g:100 ~b:255 ()))
            ~on_click:(fun () -> Some Msg.Decrement)
            ~on_mouse_enter:(fun _ -> Some (Msg.SetHover (Some Decrement)))
            ~on_mouse_leave:(fun _ -> Some (Msg.SetHover None))
            [
              Ui.text
                ~style:
                  (Ui.Style.default
                  |> Ui.Style.with_text_color
                       (Ui.Color.make ~r:255 ~g:255 ~b:255 ())
                  |> Ui.Style.with_font_size 24.0)
                " - ";
            ];
          Ui.view ~style:Styles.spacer [];
          Ui.view
            ~style:
              (Styles.button ~hovered:(hovered Increment)
                 (Ui.Color.make ~r:100 ~g:100 ~b:255 ()))
            ~on_click:(fun () -> Some Msg.Increment)
            ~on_mouse_enter:(fun _ -> Some (Msg.SetHover (Some Increment)))
            ~on_mouse_leave:(fun _ -> Some (Msg.SetHover None))
            [
              Ui.text
                ~style:
                  (Ui.Style.default
                  |> Ui.Style.with_text_color
                       (Ui.Color.make ~r:255 ~g:255 ~b:255 ())
                  |> Ui.Style.with_font_size 24.0)
                " + ";
            ];
          Ui.view ~style:Styles.spacer [];
          Ui.view
            ~style:
              (Styles.button ~hovered:(hovered Reset)
                 (Ui.Color.make ~r:200 ~g:100 ~b:100 ()))
            ~on_click:(fun () -> Some Msg.Reset)
            ~on_mouse_enter:(fun _ -> Some (Msg.SetHover (Some Reset)))
            ~on_mouse_leave:(fun _ -> Some (Msg.SetHover None))
            [
              Ui.text
                ~style:
                  (Ui.Style.default
                  |> Ui.Style.with_text_color
                       (Ui.Color.make ~r:255 ~g:255 ~b:255 ())
                  |> Ui.Style.with_font_size 18.0)
                "Reset";
            ];
        ];
      Ui.view ~style:Styles.palette_row
        ([ Ui.Color.green; Ui.Color.yellow; Ui.Color.magenta; Ui.Color.blue ]
        |> List.map (fun color ->
               Ui.view
                 ~style:(Styles.palette_option color)
                 ~on_click:(fun () -> Some (Msg.SetColor color))
                 []));
    ]

let run () =
  let handle_event = function Ui.Event.Quit -> Some Msg.Reset | _ -> None in

  let window = Ui.Window.make ~width:800 ~height:600 ~title:"Counter" () in
  Ui.run ~window ~handle_event ~model:(Model.init ()) ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
