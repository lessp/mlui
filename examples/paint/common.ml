module Tool = struct
  type t =
    | Rectangle of [ `Outline | `FilledWithOutline | `Filled ]
    | Ellipse of [ `Outline | `FilledWithOutline | `Filled ]
    | Brush of [ `S | `M | `L ]
    | Pencil
    | Line of [ `S | `M | `L ]
    | Eraser of [ `S | `M | `L ]

  let to_family_string = function
    | Rectangle _ ->
        "R"
    | Ellipse _ ->
        "E"
    | Brush _ ->
        "B"
    | Pencil ->
        "P"
    | Line _ ->
        "L"
    | Eraser _ ->
        "Er"

  let to_string = function
    | Rectangle `Outline | Ellipse `Outline ->
        "O"
    | Rectangle `FilledWithOutline | Ellipse `FilledWithOutline ->
        "FO"
    | Rectangle `Filled | Ellipse `Filled ->
        "F"
    | Brush `S ->
        "S"
    | Brush `M ->
        "M"
    | Brush `L ->
        "L"
    | Pencil ->
        "P"
    | Line `S ->
        "S"
    | Line `M ->
        "M"
    | Line `L ->
        "L"
    | Eraser `S ->
        "S"
    | Eraser `M ->
        "M"
    | Eraser `L ->
        "L"

  let is_same_family a b =
    match (a, b) with
    | Rectangle _, Rectangle _ ->
        true
    | Ellipse _, Ellipse _ ->
        true
    | Brush _, Brush _ ->
        true
    | Pencil, Pencil ->
        true
    | Line _, Line _ ->
        true
    | Eraser _, Eraser _ ->
        true
    | _ ->
        false

  let default () = Rectangle `Outline

  let rectangle_outline = Rectangle `Outline
  let rectangle_filled_with_outline = Rectangle `FilledWithOutline
  let rectangle_filled = Rectangle `Filled

  let ellipse_outline = Ellipse `Outline
  let ellipse_filled_with_outline = Ellipse `FilledWithOutline
  let ellipse_filled = Ellipse `Filled

  let brush_small = Brush `S
  let brush_medium = Brush `M
  let brush_large = Brush `L

  let pencil = Pencil

  let line_small = Line `S
  let line_medium = Line `M
  let line_large = Line `L

  let eraser_small = Eraser `S
  let eraser_medium = Eraser `M
  let eraser_large = Eraser `L

  let all_family_defaults =
    [
      rectangle_outline;
      ellipse_outline;
      brush_medium;
      pencil;
      line_medium;
      eraser_medium;
    ]

  let get_subtools = function
    | Rectangle _ ->
        Some
          [ rectangle_outline; rectangle_filled_with_outline; rectangle_filled ]
    | Ellipse _ ->
        Some [ ellipse_outline; ellipse_filled_with_outline; ellipse_filled ]
    | Brush _ ->
        Some [ brush_small; brush_medium; brush_large ]
    | Pencil ->
        None
    | Line _ ->
        Some [ line_small; line_medium; line_large ]
    | Eraser _ ->
        Some [ eraser_small; eraser_medium; eraser_large ]
end

module Position = struct
  type t = { x : int; y : int }

  let make ~x ~y = { x; y }
end

module Drawing = struct
  type shape_data =
    | TwoPoint of { start : Position.t; eend : Position.t }
    | Path of Position.t list

  type t = {
    shape_data : shape_data;
    tool : Tool.t;
    foreground : Ui.Color.t;
    background : Ui.Color.t;
  }

  let make ~start ~eend ~tool ~foreground ~background =
    { shape_data = TwoPoint { start; eend }; tool; foreground; background }

  let make_path ~points ~tool ~foreground ~background =
    { shape_data = Path points; tool; foreground; background }
end
