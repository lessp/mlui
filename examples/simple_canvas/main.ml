open Mlui

type model = unit
type msg = unit
let init () : model = ()
let update (_ : msg) (model : model) = model

module Styles = struct
  let canvas =
    Ui.Style.default
    |> Ui.Style.with_size ~width:400 ~height:300
    |> Ui.Style.with_background Ui.Color.white
    |> Ui.Style.with_padding 20
    |> Ui.Style.with_align_items Center
    |> Ui.Style.with_justify_content Center
end

let view (_ : model) : msg Ui.node =
  Ui.view ~style:Styles.canvas
    [
      Ui.canvas
        ~style:
          (Ui.Style.default
          |> Ui.Style.with_size ~width:360 ~height:260
          |> Ui.Style.with_background Ui.Color.light_gray)
        [
          Ui.rectangle ~x:20.0 ~y:20.0 ~width:120.0 ~height:80.0
            ~style:(Ui.fill Ui.Color.blue);
          Ui.ellipse ~cx:220.0 ~cy:120.0 ~rx:50.0 ~ry:35.0
            ~style:(Ui.fill_and_stroke Ui.Color.yellow Ui.Color.black 3.0);
          Ui.path
            ~points:[ (40.0, 200.0); (80.0, 230.0); (140.0, 210.0) ]
            ~style:(Ui.stroke Ui.Color.red 4.0);
        ];
    ]

let run () =
  let handle_event _ = None in
  let window = Ui.Window.make ~width:400 ~height:300 () in
  Ui.run ~window ~handle_event ~model:(init ()) ~update ~view ()

let () =
  match run () with
  | Ok () ->
      ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
