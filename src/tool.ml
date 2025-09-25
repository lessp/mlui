module BrushShape = struct
  module Thickness = struct
    type t =
      | Small
      | Medium
      | Large
  end

  type t =
    | Ellipse of Thickness.t
    | Rectangle of Thickness.t
end

module LineThickness = struct
  type t =
    | ExtraThin
    | Thin
    | Medium
    | Thick
    | ExtraThick
end

module EraserThickness = struct
  type t =
    | Small
    | Medium
    | Large
    | ExtraLarge
end

module FillStyle = struct
  type t =
    | Outline
    | FilledWithOutline
    | Filled
end

type t =
  | Brush of BrushShape.t
  | Ellipse of FillStyle.t
  | Eraser of EraserThickness.t
  | Line of LineThickness.t
  | Pencil
  | Rectangle of FillStyle.t

let default () = Rectangle FillStyle.Filled
