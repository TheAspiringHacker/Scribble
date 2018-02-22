type 'a pat = 'a pat' * Typeck_types.monotype * 'a
and 'a pat' =
  | PPair of 'a pat * 'a pat
  | PUnit
  | PVar of string * Typeck_types.polytype
  | PWild

type literal =
  | Char of char
  | Float of float
  | Int of int

type 'a expr = 'a expr' * Typeck_types.monotype * 'a

and 'a expr' =
  | EApp of 'a expr * 'a expr
  | ELam of 'a pat * 'a expr
  | ELet of 'a pat * 'a expr * 'a expr
  | ELit of literal
  | EVar of string list
