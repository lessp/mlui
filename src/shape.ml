module Size = struct
  type t =
    { width : int
    ; height : int
    }

  let make ~width ~height = { width; height }
end

module Position = struct
  type t =
    { x : int
    ; y : int
    }

  let make ~x ~y = { x; y }
end

type t =
  | Ellipsis of
      { position : Position.t
      ; size : Size.t
      }
  | Rectangle of
      { position : Position.t
      ; size : Size.t
      }

let ellipsis ~x ~y ~width ~height =
  Ellipsis { position = Position.make ~x ~y; size = Size.make ~width ~height }
;;

let rectangle ~x ~y ~width ~height =
  Rectangle { position = Position.make ~x ~y; size = Size.make ~width ~height }
;;
