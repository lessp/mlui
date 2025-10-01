# Simple Canvas Example

This minimal example demonstrates how to use `Ui.canvas` with a few static primitives:

```ocaml
Ui.canvas
  ~style:(Ui.Style.default
           |> Ui.Style.with_size ~width:360 ~height:260
           |> Ui.Style.with_background Ui.Color.light_gray)
  [
    Ui.rectangle ~x:20.0 ~y:20.0 ~width:120.0 ~height:80.0
      ~style:(Ui.fill Ui.Color.blue);
    Ui.ellipse ~cx:220.0 ~cy:120.0 ~rx:50.0 ~ry:35.0
      ~style:(Ui.fill_and_stroke Ui.Color.yellow Ui.Color.black 3.0);
    Ui.path ~points:[ (40.0, 200.0); (80.0, 230.0); (140.0, 210.0) ]
      ~style:(Ui.stroke Ui.Color.red 4.0);
  ]
```

Run locally with:

```ocaml
let window = Ui.Window.make ~width:400 ~height:300 in
Ui.run ~window ~model ~update ~view ()
```

and then:

```bash
dune exec simple_canvas
```
