open Mlui

module Msg = struct
  type t =
    | Increment
    | Decrement
    | Reset
end

module Model = struct
  type t = {
    counter : int;
  }

  let init () = {
    counter = 0;
  }
end

let update (msg: Msg.t) (model: Model.t): (Model.t * Cmd.t) =
  match msg with
  | Msg.Increment ->
      ({ counter = model.counter + 1 }, Cmd.none)
  | Msg.Decrement ->
      ({ counter = model.counter - 1 }, Cmd.none)
  | Msg.Reset ->
      ({ counter = 0 }, Cmd.none)

module Styles = struct
  let container =
    Style.(
          default
          |> with_flex_grow 1.0
          |> with_flex_direction Column
          |> with_justify_content Center
          |> with_align_items Center)

  let counter =
    Style.(
          default
          |> with_flex_direction Column
          |> with_justify_content Center
          |> with_align_items Center
          |> with_padding 20)

  let text = Style.(
    default
    |> with_font_size 18.0
    |> with_text_color Color.white)

  let button_container =
    Style.(
          default
          |> with_flex_direction Row
          |> with_justify_content Center
          |> with_align_items Center
          |> with_padding 10)

  let button =
    Style.(
          default
          |> with_flex_direction Column
          |> with_justify_content Center
          |> with_align_items Center
          |> with_background Color.blue
          |> with_padding 15
          |> with_size ~width:120 ~height:50)
end

let view (model : Model.t) =
  view
    ~style:Styles.container
    [

      view ~style:Styles.counter [
        text ~style:Styles.text (Printf.sprintf "Count: %d" model.counter);
      ];

      view ~style:Styles.button_container [
        view ~style:Styles.button ~on_click:(fun () -> Some Msg.Increment) [
          text ~style:Styles.text "Increment"
        ];

        view ~style:Styles.button ~on_click:(fun () -> Some Msg.Decrement) [
          text ~style:Styles.text "Decrement"
        ];

        view ~style:Styles.button ~on_click:(fun () -> Some Msg.Reset) [
          text ~style:Styles.text "Reset"
        ]
      ]
    ]

let subscriptions _model = Sub.on_quit Msg.Reset

let run () =
  let window = Window.make ~width:800 ~height:600 ~title:"Counter" () in
  run ~window ~subscriptions ~init:(Model.init ()) ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
