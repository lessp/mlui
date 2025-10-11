(** Style system for UI components *)

(* Dependent types *)
type flex_direction = Row | Column | RowReverse | ColumnReverse

type justify_content =
  | FlexStart
  | Center
  | FlexEnd
  | SpaceBetween
  | SpaceAround

type align_items = Stretch | Start | Center | End

type position_type = Relative | Absolute

type transform =
  | Translate of { x : float; y : float }
  | TranslateX of float
  | TranslateY of float
  | Scale of { x : float; y : float }
  | ScaleUniform of float
  | Rotate of float
  | Compose of transform list

(* Style type *)
type t = {
  background_color : Color.t option;
  border_color : Color.t option;
  border_width : float option;
  border_radius : float option;
  text_color : Color.t option;
  font_size : float option;
  padding : int option;
  margin : int option;
  width : int option;
  height : int option;
  position_type : position_type option;
  position_x : int option;
  position_y : int option;
  flex_direction : flex_direction option;
  justify_content : justify_content option;
  align_items : align_items option;
  flex_grow : float option;
  flex_shrink : float option;
  flex_basis : float option;
  transform : transform option;
}

let default =
  {
    background_color = None;
    border_color = None;
    border_width = None;
    border_radius = None;
    text_color = None;
    font_size = None;
    padding = None;
    margin = None;
    width = None;
    height = None;
    position_type = None;
    position_x = None;
    position_y = None;
    flex_direction = None;
    justify_content = None;
    align_items = None;
    flex_grow = None;
    flex_shrink = None;
    flex_basis = None;
    transform = None;
  }

let with_background color style = { style with background_color = Some color }

let with_border ~color ~width style =
  { style with border_color = Some color; border_width = Some width }

let with_border_radius radius style =
  (* Clamp radius based on dimensions to prevent rendering issues *)
  let clamped_radius =
    match (style.width, style.height) with
    | Some w, Some h ->
        let min_dim = float_of_int (min w h) in
        let max_radius = min_dim /. 2.0 *. 0.999 in
        min radius max_radius
    | _ ->
        (* No dimensions set, use radius as-is *)
        radius
  in
  { style with border_radius = Some clamped_radius }

let with_text_color color style = { style with text_color = Some color }

let with_font_size size style = { style with font_size = Some size }

let with_padding padding style = { style with padding = Some padding }

let with_size ?width ?height style =
  let style =
    match width with Some w -> { style with width = Some w } | None -> style
  in
  match height with Some h -> { style with height = Some h } | None -> style

let with_position ~x ~y style =
  { style with position_x = Some x; position_y = Some y }

let with_flex_direction direction style =
  { style with flex_direction = Some direction }

let with_justify_content justify style =
  { style with justify_content = Some justify }

let with_align_items align style = { style with align_items = Some align }

let with_flex_grow grow style = { style with flex_grow = Some grow }

let with_flex_shrink shrink style = { style with flex_shrink = Some shrink }

let with_flex_basis basis style = { style with flex_basis = Some basis }

let with_transform transform style = { style with transform = Some transform }

let with_position_type pos_type style =
  { style with position_type = Some pos_type }
