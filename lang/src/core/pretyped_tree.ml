type literal =
  | Char of char
  | Float of float
  | Int of int

type 'a pattern = 'a pattern' * 'a

and 'a pattern' =
  | PPair of 'a pattern * 'a pattern
  | PUnit
  | PVar of string
  | PWildcard

type 'a expr = 'a expr' * 'a

and 'a expr' =
  | EApp of 'a expr * 'a expr
  | ELam of 'a pattern * 'a expr
  | ELet of ('a binding list) * 'a expr
  | ELit of literal
  | EMat of 'a expr * 'a case list
  | EVar of Ident.t

and 'a binding = 'a pattern * 'a expr
and 'a case = 'a pattern * ('a expr option) * 'a expr
