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

module TVar = struct
  type t = tvar
  let compare tvar1 tvar2 =
    match tvar1, tvar2 with
    | Id _, Gen_sym _ -> -1
    | Gen_sym _, Id _-> 1
    | Id x, Id y -> compare x y
    | Gen_sym x, Gen_sym y -> compare x y
end

type polytype = {
  tvars: Set.Make(TVar).t;
  monotype : monotype
}

type env = {
  map : polytype IdMap.t
}

module TVarSet = Set.Make(TVar)
module TVarMap = Map.Make(TVar)

type substitution = monotype Map.Make(TVar).t

type state = {
  env : env;
  gensym : int
}

let fresh_var ({gensym; _} as inf) =
  ({inf with gensym = gensym + 1}, Gen_sym gensym)

module type SUBSTITUTABLE = sig
  type t
  val apply : substitution -> t -> t
  val free_tvars : t -> TVarSet.t
end

module Monotype : SUBSTITUTABLE with type t := monotype = struct
  type t = monotype
  let rec apply subst = function
    | (Var t) as v ->
      begin match TVarMap.find_opt t subst with
      | Some x -> x
      | None -> v
      end
    | Fun(t0, t1) -> Fun (apply subst t0, apply subst t1)
    | Pair(t0, t1) -> Pair (apply subst t0, apply subst t1)
    | x -> x
  let rec free_tvars = function
    | Var x -> TVarSet.singleton x
    | Unit -> TVarSet.empty
    | Fun(t0, t1) | Pair(t0, t1) ->
      TVarSet.union (free_tvars t0) (free_tvars t1)
end

module Polytype : SUBSTITUTABLE with type t := polytype = struct
  type t = polytype
  let apply subst {tvars; monotype} =
    let helper tvar acc = TVarMap.remove tvar acc in
    (* Substitution minus the polytype's bound typevars *)
    let subst' = TVarSet.fold helper tvars subst in
    {tvars = tvars; monotype = Monotype.apply subst' monotype}
  let free_tvars {tvars; monotype} =
    TVarSet.diff (Monotype.free_tvars monotype) tvars
end

module Env : SUBSTITUTABLE with type t := env = struct
  type t = env
  let apply subst {map; _} = {map = IdMap.map (Polytype.apply subst) map}
  let free_tvars {map;} =
    IdMap.fold
      (fun _ next acc -> TVarSet.union acc @@ Polytype.free_tvars next)
      map TVarSet.empty
end

let rec unify subst = function
  | t0, t1 when t0 = t1 -> Ok subst
  | Var var, mono | mono, Var var ->
      if TVarSet.mem var (Monotype.free_tvars mono)
        then Err "Recursive type unification"
        else Ok (TVarMap.add var mono subst)
  | Fun(t0, u0), Fun(t1, u1)
  | Pair(t0, u0), Pair(t1, u1) ->
      unify subst (t0, t1) >>= fun subst' -> unify subst' (u0, u1)
  | _, _ -> Err "Could not unify"

and unify_list subst zipped =
  List.fold_left
    (fun acc next -> acc >>= fun x -> unify x next)
    (Ok subst) zipped

let generalize state ty =
  let (state', tvar) = fresh_var state in (state', {
    tvars = TVarSet.singleton tvar;
    monotype = ty
  })

let instantiate {tvars; monotype} = ()
