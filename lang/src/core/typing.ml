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
  map : polytype IdMap.t
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

let rec unify subst = function
  | t0, t1 when t0 = t1 -> Ok TVarMap.empty
  | Var var, mono | mono, Var var ->
      if true then
        Err "Todo"
      else
        Err "Todo"
  | Fun(t0, u0), Fun(t1, u1)
  | Pair(t0, u0), Pair(t1, u1) ->
      unify subst (t0, t1) >>= fun s0 -> unify s0 (u0, u1)
  | _, _ -> Err "Could not unify"

and unifyList subst zipped =
  List.fold_left
    (fun acc next -> acc >>= fun x -> unify x next)
    (Ok subst) zipped

let generalize = ()
let substitute = ()
