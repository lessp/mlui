(** Style system for UI components *)

(** {1 Layout Types} *)

type flex_direction = Row | Column | RowReverse | ColumnReverse
(** Flexbox direction *)

type justify_content =
  | FlexStart
  | Center
  | FlexEnd
  | SpaceBetween
  | SpaceAround
(** Flexbox justify content alignment *)

type align_items = Stretch | Start | Center | End
(** Flexbox align items alignment *)

type position_type = Relative | Absolute
(** Position type for element positioning *)

type transform =
  | Translate of { x : float; y : float }
  | Scale of { x : float; y : float }
  | Rotate of float
  | Compose of transform list
(** Transform operations for visual effects *)

(** {1 Style Type} *)

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
(** Style type containing all visual and layout properties *)

(** {1 Constructors} *)

val default : t
(** Default style with all properties set to None *)

(** {1 Style Builders} *)

val with_background : Color.t -> t -> t
(** Set background color *)

val with_border : color:Color.t -> width:float -> t -> t
(** Set border color and width *)

val with_border_radius : float -> t -> t
(** Set border radius for rounded corners *)

val with_text_color : Color.t -> t -> t
(** Set text color *)

val with_font_size : float -> t -> t
(** Set font size *)

val with_padding : int -> t -> t
(** Set padding *)

val with_size : ?width:int -> ?height:int -> t -> t
(** Set width and/or height *)

val with_position : x:int -> y:int -> t -> t
(** Set absolute position coordinates *)

val with_flex_direction : flex_direction -> t -> t
(** Set flexbox direction *)

val with_justify_content : justify_content -> t -> t
(** Set flexbox justify content *)

val with_align_items : align_items -> t -> t
(** Set flexbox align items *)

val with_flex_grow : float -> t -> t
(** Set flex grow factor *)

val with_flex_shrink : float -> t -> t
(** Set flex shrink factor *)

val with_flex_basis : float -> t -> t
(** Set flex basis *)

val with_position_type : position_type -> t -> t
(** Set position type (Relative or Absolute) *)

val with_transform : transform -> t -> t
(** Set transform for visual effects *)
