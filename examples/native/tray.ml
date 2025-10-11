open Mlui

module Model = struct
  type t = {
    tray : Tray.t;
    window_visible : bool;
  }

  let init () =
    let tray = Tray.make () in
    let _ = Tray.set_title tray ~text:"mlui (click to hide)" in
    { tray; window_visible = true }
end

module Msg = struct
  type t = TrayClicked
end

let update msg model =
  match msg with
  | Msg.TrayClicked ->
      let new_visible = not model.Model.window_visible in
      let icon = if new_visible then "mlui (click to hide)" else "mlui (click to show)" in
      let _ = Tray.set_title model.Model.tray ~text:icon in
      let cmd = if new_visible then Cmd.show_window else Cmd.hide_window in
      Printf.printf "Tray clicked! new_visible=%b, cmd=%s\n%!" new_visible
        (if new_visible then "show" else "hide");
      ({ model with Model.window_visible = new_visible }, cmd)

let view model =
  let status =
    if model.Model.window_visible then "Window is visible"
    else "Window is hidden"
  in

  view
    ~style:Style.(default
            |> with_padding 40
            |> with_flex_direction Column
            |> with_align_items Center
            |> with_background Color.white)
    [
      text
        ~style:Style.(default
                |> with_font_size 32.0
                |> with_text_color Color.black)
        "🔔 System Tray Demo";

      view
        ~style:Style.(default |> with_padding 20)
        [];

      text
        ~style:Style.(default
                |> with_font_size 18.0
                |> with_text_color Color.dark_gray)
        status;

      view
        ~style:Style.(default |> with_padding 15)
        [];

      text
        ~style:Style.(default
                |> with_font_size 14.0
                |> with_text_color Color.gray)
        "Click the tray icon to toggle window visibility";
    ]

let subscriptions model =
  Sub.Tray.on_click model.Model.tray Msg.TrayClicked

let () =
  let window = Window.make ~width:450 ~height:300 ~title:"Tray Demo" () in
  match run ~window ~subscriptions ~init:(Model.init ()) ~update ~view () with
  | Ok () -> ()
  | Error (`Msg msg) ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
