open Tsdl
open LetSyntax.Result

let run () =
  let* () = Sdl.init Sdl.Init.(video + events) in

  Sdl.gl_set_attribute Sdl.Gl.context_major_version 2 |> ignore;
  Sdl.gl_set_attribute Sdl.Gl.context_minor_version 1 |> ignore;

  let* window = Sdl.create_window "ML Paint" ~w:800 ~h:600 Sdl.Window.(opengl) in
  let* gl_context = Sdl.gl_create_context window in
  let* () = Sdl.gl_make_current window gl_context in

  let renderer_state = Renderer.create_renderer ~width:800 ~height:600 in
  let model = ref (App.Model.default ()) in
  let e = Sdl.Event.create () in

  let rec loop () =
    Renderer.render_model renderer_state !model;
    Sdl.gl_swap_window window;

    match Sdl.poll_event (Some e) with
    | false -> loop ()
    | true ->
      (match EventMapper.sdl_event_to_msg e with
       | Some App.Msg.Quit -> ()
       | Some msg ->
         model := App.update msg !model;
         loop ()
       | None -> loop ())
  in

  loop ();
  Sdl.gl_delete_context gl_context;
  Sdl.destroy_window window;
  Sdl.quit ()
;;
