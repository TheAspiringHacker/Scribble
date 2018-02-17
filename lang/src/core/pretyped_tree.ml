type 'a qual_id = (string * 'a) list

type 'a literal = literal' * 'a

and literal' = Int | Char

type 'a expr = 'a expr' * 'a

and 'a expr' =
  | App of 'a expr * 'a expr
  | Lambda of 'a pattern * 'a expr
  | Let of 'a pattern * 'a expr * 'a expr
  | Literal of 'a literal
  | Var of 'a qual_id

and 'a pattern = 'a pattern' * 'a

and 'a pattern' =
  | PPair of 'a pattern * 'a pattern
  | PUnit
  | PVar of string
  | PWildcard
