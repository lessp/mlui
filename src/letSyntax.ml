module Result = struct
  let ( let* ) result f =
    match result with
    | Ok x -> f x
    | Error (`Msg e) -> failwith e
  ;;
end
