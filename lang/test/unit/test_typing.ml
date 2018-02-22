print_endline "Begin typing test"

let programs = [
    (Pretyped_tree.Literal (Pretyped_tree.Int 1), ()),
    (Pretyped_tree.Literal (Pretyped_tree.Char 'o'), ()),
    (Pretyped_tree.Lambda (
         (Pretyped_tree.PVar "x", ()),
         (Pretyped_tree.Literal (Int 1), ())),
         ())
  ]
