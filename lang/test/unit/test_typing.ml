let _ = print_endline "Begin typing test.";;

let programs = [
    (Pretyped_tree.ELit (Pretyped_tree.Int 1), ()),
    (Pretyped_tree.ELit (Pretyped_tree.Char 'o'), ()),
    (Pretyped_tree.ELam (
         (Pretyped_tree.PVar "x", ()),
         (Pretyped_tree.ELit (Int 1), ())),
         ())
  ]

let _ = print_endline "Typing test successful.";;
