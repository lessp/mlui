open Mlui

type model = unit
type msg = unit
let init () : model = ()
let update (_ : msg) (model : model) = (model, Cmd.none)

module Styles = struct
  let canvas =
    Style.default
    |> Style.with_size ~width:400 ~height:300
    |> Style.with_background Color.white
    |> Style.with_padding 20
    |> Style.with_align_items Center
    |> Style.with_justify_content Center
end

let view (_ : model) : msg Ui.node =
  Ui.view ~style:Styles.canvas
    [
      Ui.canvas
        ~style:
          (Style.default
          |> Style.with_size ~width:360 ~height:260
          |> Style.with_background Color.light_gray)
        [
          Ui.rectangle ~x:20.0 ~y:20.0 ~width:120.0 ~height:80.0
            ~style:(Ui.fill Color.blue);
          Ui.ellipse ~cx:220.0 ~cy:120.0 ~rx:50.0 ~ry:35.0
            ~style:(Ui.fill_and_stroke Color.yellow Color.black 3.0);
          Ui.path
            ~points:[ (40.0, 200.0); (80.0, 230.0); (140.0, 210.0) ]
            ~style:(Ui.stroke Color.red 4.0);
        ];
    ]

let run () =
  let window = Window.make ~width:400 ~height:300 () in
  Ui.run ~window ~init:(init ()) ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
