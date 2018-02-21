(* This is the type inferencer *)

open Types
open Util
module TypeResult = Result(struct type t = string end)
open TypeResult
module TVarSet = Set.Make(TVar)
module TVarMap = Map.Make(TVar)

(* A substitution is a mapping of type variables to monotypes *)
type substitution = monotype TVarMap.t
type state = {
  env : env;
  gensym : int list;
  current_level : int;
}


let fresh_var kind st =
  ({level = st.current_level; id = List.hd st.gensym; var_kind = kind},
   {st with gensym = ((List.hd st.gensym) + 1)::(List.tl st.gensym)})

let increase_level st =
  {st with current_level = st.current_level + 1; gensym = 0::st.gensym}
let decrease_level st =
  {st with current_level = st.current_level - 1; gensym = List.tl st.gensym}

module type SUBSTITUTABLE = sig
  type t
  val apply : substitution -> t -> t
end

module Monotype : SUBSTITUTABLE with type t := monotype = struct
  type t = monotype
  let rec apply subst = function
    | TApp(t0, t1) -> TApp(apply subst t0, apply subst t1)
    | (TCon _) as t -> t
    | (TVar t) as v ->
      match TVarMap.find_opt t subst with
      | Some x -> x
      | None -> v
end

(* Turns a monotype into a polytype by quantifying over free tvars *)
let generalize level monotype =
  let rec helper ((map, list, count) as acc) = function
    | TApp(t0, t1) ->
       let acc, q0 = helper acc t0 in
       let acc, q1 = helper acc t1 in
       acc, QApp(q0, q1)
    | TCon constr -> (acc, QCon constr)
    | TVar tvar ->
       if tvar.level > level then
         match TVarMap.find_opt tvar map with
         | Some idx -> (acc, QBound idx)
         | None ->
            ((TVarMap.add tvar count map, (tvar.var_kind)::list, count + 1),
             QBound count)
       else
         (acc, QFree tvar)
  in let ((_, list, _), qty) = helper (TVarMap.empty, [], 0) monotype in
     {tvars = Array.of_list @@ List.rev list; quantitype = qty}

(* Turns a polytype into a monotype, replacing the qvars with fresh tvars *)
let instantiate st polytype =
  (* Generate an array of fresh type variables *)
  let ls, st = Array.fold_left (fun (ls, st) kind ->
                   let (tvar, st) = (fresh_var kind st) in (tvar::ls, st)
                 ) ([], st) polytype.tvars
  in let array = Array.of_list @@ List.rev ls in
     (* Helper function that replaces qvars with tvars from the array *)
     let rec helper = function
       | QApp(t0, t1) -> TApp(helper t0, helper t1)
       | QBound idx -> TVar (array.(idx))
       | QFree tvar -> TVar tvar
       | QCon constr -> TCon constr
     in (helper polytype.quantitype, st)

let rec occurs tvar = function
  | TVar tvar1 -> tvar = tvar1
  | TApp(t0, t1) -> (occurs tvar t0) && (occurs tvar t1)
  | TCon _ -> false

let rec unify subst = function
  | (TVar tv0, TVar tv1) when tv0 = tv1 -> Ok subst
  | (TVar tv, t) | (t, TVar tv) ->
      if occurs tv t
        then Err "Recursive unification"
        else Ok(TVarMap.add tv t subst)
  | (TApp(t0, t1), TApp(t2, t3)) ->
      unify subst (t0, t1) >>= fun subst ->
      unify subst (Monotype.apply subst t2, Monotype.apply subst t3)
  | (TCon c0, TCon c1) when c0 = c1 -> Ok subst
  | _ -> Err "Could not unify"

let walk_pattern st pattern =
  let rec helper acc st (node, ann) =
    match node with
    | Pretyped_tree.PVar id ->
        begin match IdSet.find_opt [id] acc with
        | None ->
          let (tvar, st) = fresh_var KStar st in
          let tvar = TVar tvar in
            Ok (tvar, IdSet.add [id] acc, { st with
              env = {map = IdMap.add [id] (poly_of_mono tvar) st.env.map}
            })
        | Some _ -> Err "already defined"
        end
    | Pretyped_tree.PPair(fst, snd) ->
        helper acc st fst >>= fun (fst_type, acc, st) ->
        helper acc st snd >>= fun (snd_type, acc, st) ->
        Ok (TApp(TApp(TCon TPair, fst_type), snd_type), acc, st)
    | Pretyped_tree.PUnit -> Ok (TCon TUnit, acc, st)
    | Pretyped_tree.PWildcard ->
        let (tvar, st) = fresh_var KStar st in Ok (TVar tvar, acc, st)
  in helper IdSet.empty st pattern >>= fun (ty, _, st) -> Ok (ty, st)
