open Mlui

module Msg = struct
  type t = ShowAlert
end

let update msg model =
  match msg with
  | Msg.ShowAlert ->
      Cocoa.show_alert "Hello from mlui! 🎉";
      (model, Cmd.none)

let view _model =
  view
    ~style:Style.(default
            |> with_padding 40
            |> with_flex_direction Column
            |> with_align_items Center)
    [
      text
        ~style:Style.(default
                |> with_font_size 24.0
                |> with_text_color Color.black)
        "Cocoa FFI Test";

      view
        ~style:Style.(default
                |> with_padding 20
                |> with_background Color.blue
                |> with_border_radius 8.0)
        ~on_click:(fun () -> Some Msg.ShowAlert)
        [
          text
            ~style:Style.(default |> with_text_color Color.white)
            "Click to Show Alert"
        ];
    ]

let () =
  let window = Window.make ~width:400 ~height:300 ~title:"Cocoa FFI Test" () in
  match run ~window ~init:() ~update ~view () with
  | Ok () -> ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
