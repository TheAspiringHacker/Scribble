type kind = KStar | KFun of kind * kind

type tycon = TFun | TUnit | TPair | TInt | TBool | TChar | TFloat

type ty =
  | TApp of ty * ty
  | TCon of tycon
  | TVar of int * int

type ty_scheme = Forall of (kind array) * ty

type ('node, 'ann) ast = {
    node : 'node;
    ty : ty;
    ann : 'ann;
  }

type 'a pat = ('a pat', 'a) ast
and 'a pat' =
  | PPair of 'a pat * 'a pat
  | PUnit
  | PVar of string
  | PWild

type literal =
  | Char of char
  | Float of float
  | Int of int

type 'a expr = ('a expr', 'a) ast

and 'a expr' =
  | EApp of 'a expr * 'a expr
  | ELam of 'a pat * 'a expr
  | ELet of ('a binding list) * 'a expr
  | ELit of literal
  | EMat of 'a expr * ('a case list)
  | EVar of Ident.t

and 'a binding = 'a pat * 'a expr

and 'a case = 'a pat * 'a expr option * 'a expr
