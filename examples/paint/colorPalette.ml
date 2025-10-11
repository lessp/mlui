open Mlui

module Msg = struct
  type t =
    | SetForegroundColor of Color.t
    | SetBackgroundColor of Color.t
    | SwapColors
end

module Styles = struct
  open Mlui

  let container =
    Style.default
    |> Style.with_background Color.light_gray
    |> Style.with_flex_direction Row
    |> Style.with_align_items Center

  let color_palette =
    Style.default
    |> Style.with_justify_content Center
    |> Style.with_align_items Center
    |> Style.with_padding 10
end

let all_colors =
  Color.
    [
      (* top row *)
      [ black; dark_gray; magenta; green; cyan ];
      (* bottom row *)
      [ white; light_gray; red; yellow; blue ];
    ]

let view ~foreground ~background =
  Ui.view ~style:Styles.container
    [
      (* Current selected colors *)
      Ui.view
        ~style:
          Style.(
            default
            |> with_background Color.light_gray
            |> with_flex_direction Row |> with_padding 5)
        [
          Ui.view
            ~style:
              Style.(
                default |> with_background foreground
                |> with_size ~width:40 ~height:40)
            ~on_click:(fun () -> Some Msg.SwapColors)
            [];
          Ui.view
            ~style:
              Style.(
                default |> with_background background
                |> with_size ~width:40 ~height:40)
            ~on_click:(fun () -> Some Msg.SwapColors)
            [];
        ];
      (* Color palette *)
      Ui.view
        ~style:
          Style.(default |> with_flex_direction Column |> with_padding 5)
        (all_colors
        |> List.map @@ fun row ->
           Ui.view
             ~style:(Style.default |> Style.with_flex_direction Row)
             (row
             |> List.map @@ fun color ->
                Ui.view
                  ~style:
                    Style.(
                      default |> with_background color
                      |> with_size ~width:25 ~height:25)
                  ~on_click:(fun () -> Some (Msg.SetForegroundColor color))
                  []));
    ]
