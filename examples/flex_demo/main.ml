open Mlui

module Styles = struct
  open Mlui

  let root =
    Style.default
    |> Style.with_background Color.light_gray
    |> Style.with_flex_direction Column
    |> Style.with_padding 10

  let row =
    Style.default
    |> Style.with_flex_direction Row
    |> Style.with_flex_grow 1.0 |> Style.with_padding 8

  let column =
    Style.default
    |> Style.with_flex_direction Column
    |> Style.with_flex_grow 1.0 |> Style.with_padding 8

  let box color =
    Style.default |> Style.with_flex_grow 1.0
    |> Style.with_background color
    |> Style.with_align_items Center
    |> Style.with_justify_content Center
end

let render_box label style color =
  Ui.view ~style:(style color)
    [
      Ui.text
        ~style:(Style.default |> Style.with_text_color Color.white)
        label;
    ]

let view (_ : unit) : unit Ui.node =
  Ui.view ~style:Styles.root
    [
      Ui.view ~style:Styles.row
        [
          render_box "Row A" Styles.box Color.blue;
          render_box "Row B" Styles.box Color.green;
        ];
      Ui.view ~style:Styles.column
        [
          render_box "Column A" Styles.box Color.red;
          render_box "Column B" Styles.box Color.yellow;
        ];
    ]

let run () =
  let window = Window.make ~width:1024 ~height:768 ~title:"Flex Demo" () in
  Mlui.run ~window ~init:() ~update:(fun _ model -> (model, Cmd.none)) ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
