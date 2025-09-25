type t =
  | Idle
  | DrawingRectangle of { start_pos : Shape.Position.t }
