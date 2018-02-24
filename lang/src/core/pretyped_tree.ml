

type literal =
  | Char of char
  | Float of float
  | Int of int

type 'a expr = 'a expr' * 'a

and 'a expr' =
  | App of 'a expr * 'a expr
  | Lambda of 'a pattern * 'a expr
  | Let of 'a pattern * 'a expr * 'a expr
  | Literal of literal
  | Var of Ident.t

and 'a pattern = 'a pattern' * 'a

and 'a pattern' =
  | PPair of 'a pattern * 'a pattern
  | PUnit
  | PVar of string
  | PWildcard
