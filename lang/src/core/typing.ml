(* I am using http://dev.stephendiehl.com/fun/006_hindley_milner.html and
   https://github.com/quchen/articles/tree/master/hindley-milner as guides *)
(* I'm going to deviate from the tutorials a little bit because they don't
   support pattern matching *)

open Util
module TyResult = Result(struct type t = string end)
open TyResult
module IdMap = Map.Make(struct
  type t = string list
  let compare = Pervasives.compare
end)
module IdSet = Set.Make(struct
  type t = string list
  let compare = Pervasives.compare
end)

type tvar = Id of string | Gen_sym of int

(* A monotype is a regular type *)
type monotype =
  | Fun of monotype * monotype
  | Pair of monotype * monotype
  | Unit
  | Var of tvar
  | Int | Char

module TVar = struct
  type t = tvar
  let compare tvar1 tvar2 =
    match tvar1, tvar2 with
    | Id _, Gen_sym _ -> -1
    | Gen_sym _, Id _-> 1
    | Id x, Id y -> compare x y
    | Gen_sym x, Gen_sym y -> compare x y
end

(* A polytype, or type scheme, is a generic type (quantifies type variables ) *)
type polytype = {
  tvars: Set.Make(TVar).t;
  monotype : monotype
}

(* An environment is a mapping of variables to polytypes *)
type env = {
  map : polytype IdMap.t
}

module TVarSet = Set.Make(TVar)
module TVarMap = Map.Make(TVar)

(* A substitution is a mapping of type variables to monotype *)
type substitution = monotype TVarMap.t

type constrain = Unify of monotype * monotype

type collection_state = {
  env : env;
  subst : substitution;
  constraints : constrain list;
  gensym : int;
}

let fresh_var ({gensym; _} as inf) =
  (Gen_sym gensym, {inf with gensym = gensym + 1})

module type SUBSTITUTABLE = sig
  type t
  (* Replace all occurences of assigned free variables
     with their assignments in the substitution *)
  val apply : substitution -> t -> t
  (* Gather all the type variables that are not quantified by a polytype *)
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
    | Fun(t0, t1) | Pair(t0, t1) ->
      TVarSet.union (free_tvars t0) (free_tvars t1)
    | _ -> TVarSet.empty
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

(* Compute the substitution that would make the two types the same *)
let rec unify subst = function
  | t0, t1 when t0 = t1 -> Ok subst
  | Var var, mono | mono, Var var ->
      if TVarSet.mem var (Monotype.free_tvars mono)
        then Err "Recursive type unification"
        else Ok (TVarMap.add var mono subst)
  | Fun(t0, u0), Fun(t1, u1)
  | Pair(t0, u0), Pair(t1, u1) ->
      unify subst (t0, t1) >>= fun subst -> unify subst (u0, u1)
  | _, _ -> Err "Could not unify"

and unify_list subst zipped =
  List.fold_left
    (fun acc next -> acc >>= fun x -> unify x next)
    (Ok subst) zipped

let poly_of_mono ty = {tvars = TVarSet.empty; monotype = ty}

let walk_pattern state pattern =
  let rec helper acc state (node, ann) =
    match node with
    | Pretyped_tree.PVar id ->
        begin match IdSet.find_opt [id] acc with
        | None ->
          let (tvar, state) = fresh_var state in
          let tvar = Var tvar in
            Ok (tvar, IdSet.add [id] acc, { state with
              env = {map = IdMap.add [id] (poly_of_mono tvar) state.env.map}
            })
        | Some _ -> Err "already defined"
        end
    | Pretyped_tree.PPair(fst, snd) ->
        helper acc state fst >>= fun (fst_type, acc, state) ->
        helper acc state snd >>= fun (snd_type, acc, state) ->
        Ok (Pair(fst_type, snd_type), acc, state)
    | Pretyped_tree.PUnit -> Ok (Unit, acc, state)
    | Pretyped_tree.PWildcard ->
        let (tvar, state) = fresh_var state in Ok (Var tvar, acc, state)
  in helper IdSet.empty state pattern >>= fun (ty, _, state) -> Ok (ty, state)

  (* Given a monotype and an environment, return all variables not quantified in
     the environment *)
  (* Maybe we can optimize by using the "levels" / ownership concept used in the
     OCaml type inferencer? *)
  let generalize env ty =
    let free_tvars = Monotype.free_tvars ty in
    let free_tvars' = TVarSet.diff free_tvars @@ Env.free_tvars env in
    let quantified_vars = TVarSet.fold TVarSet.add TVarSet.empty free_tvars' in
    { tvars = quantified_vars; monotype = ty }

let instantiate {tvars; monotype} = () (* TODO *)

(* Gather unification requirements *)
(* TODO *)
let rec collect_constraints state (node, ann) =
  match node with
  | Pretyped_tree.App(f, x) ->
      (* Infer function type *)
      collect_constraints state f >>= fun (f_type, state) ->
      (* Infer argument type *)
      collect_constraints state x >>= fun (arg_type, state) ->
      let tvar, state = fresh_var state in
      let constr = Unify(f_type, Fun(arg_type, Var tvar)) in
      Ok(Var tvar, { state with constraints = constr::state.constraints })
  | Pretyped_tree.Lambda(pattern, body) ->
      walk_pattern state pattern >>= fun (param_type, state) ->
      collect_constraints state body >>= fun (return_type, state) ->
      Ok(Fun(param_type, return_type), state)
  | Pretyped_tree.Let((Pretyped_tree.PVar id, p'ann), bound, body) ->
      collect_constraints state bound >>= fun (bound_type, state) ->
      let state = { state with
        env = {                 (* vv Let generalization vv *)
          map = IdMap.add [id] (generalize state.env bound_type) state.env.map
        }
      } in collect_constraints state body
  | Pretyped_tree.Let(pattern, bound, body) ->
      (* Monomorphism restriction occurs here (no let generalization) *)
      walk_pattern state pattern >>= fun (pattern_type, state) ->
      collect_constraints state bound >>= fun (bound_type, state) ->
      let constr = Unify(pattern_type, bound_type) in
      collect_constraints { state with
        constraints = constr::state.constraints
      } body >>= fun (body_type, state) ->
      Ok(body_type, state)
  | _ -> Err "TODO"
