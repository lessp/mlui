module Layer = struct
  type t = { id : int }
end

type t =
  { background : Color.t
  ; layers : Layer.t list
  }
