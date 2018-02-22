type 'a qual_id = string list

and literal =
  | Char of char
  | Float of float
  | Int of int

type 'a expr = 'a expr' * 'a

and 'a expr' =
  | App of 'a expr * 'a expr
  | Lambda of 'a pattern * 'a expr
  | Let of 'a pattern * 'a expr * 'a expr
  | Literal of literal
  | Var of 'a qual_id

and 'a pattern = 'a pattern' * 'a

and 'a pattern' =
  | PPair of 'a pattern * 'a pattern
  | PUnit
  | PVar of string
  | PWildcard
