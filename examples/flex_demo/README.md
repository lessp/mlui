# Flex Demo

This example demonstrates how to use flexbox layout with `Ui.view` to create responsive layouts with colored boxes.

The demo creates a flex container with two sections:
- A horizontal row containing two boxes (blue "Row A" and green "Row B")
- A vertical column containing two boxes (red "Column A" and yellow "Column B")

```ocaml
let view (_ : unit) : unit Ui.node =
  Ui.view ~style:Styles.root
    [
      Ui.view ~style:Styles.row
        [
          render_box "Row A" Styles.box Ui.Color.blue;
          render_box "Row B" Styles.box Ui.Color.green;
        ];
      Ui.view ~style:Styles.column
        [
          render_box "Column A" Styles.box Ui.Color.red;
          render_box "Column B" Styles.box Ui.Color.yellow;
        ];
    ]
```

Key flexbox properties demonstrated:
- `with_flex_direction` - Controls whether children are laid out in rows or columns
- `with_flex_grow` - Makes elements expand to fill available space
- `with_padding` - Adds spacing around elements
- `with_align_items` and `with_justify_content` - Centers text within boxes

Run the demo with:

```bash
dune exec flex_demo
```

This will open a 1024×768 window displaying the flex layout.