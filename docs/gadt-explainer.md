# Why `Ui.node` is a GADT

We want one tree type that supports different node kinds:

```ocaml
Ui.view      (* has children and view-specific handlers    *)
Ui.text      (* only text + optional click handler         *)
Ui.canvas    (* has primitives instead of children         *)
```

Without a GADT we’d need a big record with lots of `option` fields, or store “children” even when a node can’t have any. Using a GADT we can give each constructor exactly the fields it needs while still returning the same type `'msg node`:

```ocaml
| View   : { style; children : 'msg node list; ... } -> 'msg node
| Text   : { content; ... } -> 'msg node
| Canvas : { primitives; ... } -> 'msg node
| Empty  : 'msg node
```

That unlocks a simple `map_msg`:

```ocaml
val map_msg : ('a -> 'b) -> 'a node -> 'b node
```

We just pattern match each constructor and remap the handler fields. The type tells us each handler emits `'a`, so we can compose with the user’s function.

Concrete example (canvas + text in the same tree):

```ocaml
Ui.view
  [ Ui.canvas ~on_mouse_move:(fun _ -> Some CanvasMsg) primitives
  ; Ui.text   ~on_click:(fun () -> Some LabelClicked) "Pick a colour"
  ]
```

Both children return `msg Ui.node` even though one has primitives and the other has text. Because each constructor’s record is specialised, you don’t have to pass meaningless fields (like an empty children list for the canvas).

So the GADT keeps the tree type tidy, preserves static typing for handlers, and lets us build a `map_msg` that composes components in the Elm style.
