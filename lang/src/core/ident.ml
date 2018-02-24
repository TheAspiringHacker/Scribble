type ident = Local of string | Qual of string list

type t = ident

let compare x y =
  match (x, y) with
  | (Local _), (Qual _) -> -1
  | (Qual _), (Local _) -> 1
  | (Local str0), (Local str1) -> String.compare str0 str1
  | (Qual list0), (Qual list1) -> compare list0 list1
