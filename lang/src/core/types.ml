
module IdMap = Map.Make(struct
  type t = string list
  let compare = Pervasives.compare
end)

module IdSet = Set.Make(struct
  type t = string list
  let compare = Pervasives.compare
end)

type tycon = TFun | TPair | TUnit

type kind = KStar | KFun

type tvar = {
  level : int;
  id : int;
  var_kind : kind;
}

module TVar = struct
  type t = tvar
  let compare tvar1 tvar2 =
    if tvar1.level < tvar2.level then -1
    else if tvar1.level > tvar2.level then 1
    else if tvar1.id < tvar2.id then -1
    else if tvar1.id > tvar2.id then 1
    else 0
end

(* A monotype is a regular type *)
type monotype =
  | TApp of monotype * monotype
  | TCon of tycon
  | TVar of tvar

(* A quantitype is the body of a type scheme *)
type quantitype =
  | QApp of quantitype * quantitype
  | QBound of int
  | QFree of tvar
  | QCon of tycon

type 'a pred = string list * 'a

(* A polytype, or type scheme, is a generic type (quantifies type variables ) *)
type polytype = {
  tvars : kind array;
  quantitype : quantitype
}

(* An environment is a mapping of variables to polytypes *)
type env = {
  map : polytype IdMap.t
}

let poly_of_mono mono =
  let rec helper = function
    | TApp(t0, t1) -> QApp(helper t0, helper t1)
    | TCon c -> QCon c
    | TVar tv -> QFree tv
  in {tvars = [||]; quantitype = helper mono}
