type 'a pat = 'a pat' * 'a
and 'a pat' =
  | PPair of 'a pat * 'a pat
  | PUnit
  | PVar of string
  | PWild

type literal =
  | Char of char
  | Float of float
  | Int of int

type 'a expr = 'a expr' * 'a

and 'a expr' =
  | EApp of 'a expr * 'a expr
  | ELam of 'a pat * 'a expr
  | ELet of ('a binding list) * 'a expr
  | ELit of literal
  | EMat of 'a expr * ('a case list)
  | EVar of Ident.t

and 'a binding = 'a pat * 'a expr

and 'a case = 'a pat * 'a expr option * 'a expr
