open Util
module TyResult = Result(struct type t = string end)
open TyResult
module IdMap = Map.Make(struct
  type t = string list
  let compare = Pervasives.compare
end)

type tvar = Id of string | Gen_sym of int

type monotype =
  | Fun of monotype * monotype
  | Pair of monotype * monotype
  | Unit
  | Var of tvar

type polytype = {
  monotype : monotype
}

type env = {
  map : monotype IdMap.t
}

module TVar = struct
  type t = tvar
  let compare tvar1 tvar2 =
    match tvar1, tvar2 with
    | Id _, Gen_sym _ -> -1
    | Gen_sym _, Id _-> 1
    | Id x, Id y -> compare x y
    | Gen_sym x, Gen_sym y -> compare x y
end

module TVarMap = Map.Make(TVar)

type substitution = monotype Map.Make(TVar).t

type state = {
  env : env;
  gensym : int
}

let fresh_var ({gensym; _} as inf) =
  (Gen_sym gensym, {inf with gensym = gensym + 1})

let rec unify = function
  | t0, t1 when t0 = t1 -> Ok TVarMap.empty
  | Var var, mono | mono, Var var -> Err "Todo"
  | Fun(in0, out0), Fun(in1, out1) ->
      unify(in0, in1) >>= fun s0 -> unify(out0, out1) >>= fun s1 -> Err "Todo"
  | _, _ -> Err "Could not unify"

let generalize = ()
let substitute = ()
