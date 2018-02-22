(**
This is the type inferencer. The current steps are to
  0. Generate constraints and a typed tree from a pretyped tree
  1. Solve the constraints at the let bindings
  2. Check for unquantified type variables and return a core AST (TODO)

This type inferencer uses the optimization of "levels" from the OCaml
type inferencer to determine which type variables to quantify. See
http://okmij.org/ftp/ML/generalization.html.
 *)

open Typeck_types
open Typed_tree
open Util

module TypeResult = Result(struct type t = string end)
open TypeResult

module TVarSet = Set.Make(TVar)
module TVarMap = Map.Make(TVar)

(* A substitution is a mapping of type variables to monotypes *)
type substitution = monotype TVarMap.t

type constrain = Unify of monotype * monotype

type state = {
  env : env;
  subst : substitution;
  gensym : int list;
  constraints : constrain list;
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

(** Turns a monotype into a polytype by quantifying over free tvars *)
let generalize level monotype =
  let rec helper ((map, list, count) as acc) = function
    | TApp(t0, t1) ->
       let acc, q0 = helper acc t0 in
       let acc, q1 = helper acc t1 in
       acc, QApp(q0, q1)
    | TCon constr -> (acc, QCon constr)
    | TVar tvar ->
       (* The tvar's level must be greater than the current level *)
       if tvar.level > level then
         match TVarMap.find_opt tvar map with
         | Some idx -> (acc, QBound idx)
         | None ->
            ((TVarMap.add tvar count map, tvar::list, count + 1),
             QBound count)
       else
         (acc, QFree tvar)
  in let ((_, list, _), qty) = helper (TVarMap.empty, [], 0) monotype in
     {tvars = Array.of_list @@ List.rev list; quantitype = qty}

(** Turns a polytype into a monotype, replacing the qvars with fresh tvars *)
let instantiate st polytype =
  (* Generate an array of fresh type variables *)
  let ls, st = Array.fold_left (fun (ls, st) tvar ->
                   let (tvar, st) = (fresh_var tvar.var_kind st) in
                   (tvar::ls, st)
                 ) ([], st) polytype.tvars
  in let array = Array.of_list @@ List.rev ls in
     (* Helper function that replaces qvars with tvars from the array *)
     let rec helper = function
       | QApp(t0, t1) -> TApp(helper t0, helper t1)
       | QBound idx -> TVar (array.(idx))
       | QFree tvar -> TVar tvar
       | QCon constr -> TCon constr
     in (helper polytype.quantitype, st)

(** Does a type variable appear in a type? *)
let rec occurs tvar = function
  | TVar tvar1 -> tvar = tvar1
  | TApp(t0, t1) -> (occurs tvar t0) && (occurs tvar t1)
  | TCon _ -> false

(** Unify two types and extend a substitution *)
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

(** Unify a list of monotype pairs *)
let solve m = function
  | [] -> m
  | Unify(t0, t1)::xs ->
     m >>= fun subst ->
     unify subst (Monotype.apply subst t0, Monotype.apply subst t1)

(** Walk a pattern, introducing variables into the environment *)
let walk_pattern st pattern =
  let rec helper acc st (node, ann) =
    match node with
    | Pretyped_tree.PVar id ->
        begin match IdSet.find_opt [id] acc with
        | None ->
          let (tvar, st) = fresh_var KStar st in
          let tvar = TVar tvar in
          let poly = poly_of_mono tvar in
            Ok ((PVar(id, poly), tvar, ann), IdSet.add [id] acc, { st with
              env = {map = IdMap.add [id] poly st.env.map}
            })
        | Some _ -> Err "already defined"
        end
    | Pretyped_tree.PPair(fst, snd) ->
        helper acc st fst >>= fun ((_, fst_type, _) as fst, acc, st) ->
        helper acc st snd >>= fun ((_, snd_type, _) as snd, acc, st) ->
        let ty = TApp(TApp(TCon TPair, fst_type), snd_type) in
        Ok ((PPair(fst, snd), ty, ann), acc, st)
    | Pretyped_tree.PUnit -> Ok ((PUnit, TCon TUnit, ann), acc, st)
    | Pretyped_tree.PWildcard ->
        let (tvar, st) = fresh_var KStar st in
        Ok ((PWild, TVar tvar, ann), acc, st)
  in helper IdSet.empty st pattern >>= fun (pat, _, st) -> Ok (pat, st)

(** Given a pretyped tree, return a typed tree and constraints *)
let rec gen_constraints st (node, ann) =
  match node with
  | Pretyped_tree.App(f, x) ->
     gen_constraints st f >>= fun ((_, f_ty, _) as f_typed, st) ->
     gen_constraints st x >>= fun ((_, x_ty, _) as x_typed, st) ->
     let tv, st = fresh_var KStar st in
     let t = TApp(TApp(TCon TFun, x_ty), TVar tv) in
     let st = { st with constraints = Unify(t, f_ty)::st.constraints } in
     Ok ((EApp(f_typed, x_typed), TVar tv, ann), st)
  | Pretyped_tree.Lambda(pat, body) ->
     walk_pattern st pat >>= fun ((_, in_ty, _) as pat_typed, st) ->
     gen_constraints st body >>= fun((_, out_ty, _) as body_typed, st) ->
     let ty = TApp(TApp(TCon TFun, in_ty), out_ty) in
     Ok((ELam(pat_typed, body_typed), ty, ann), st)
  | Pretyped_tree.Let((Pretyped_tree.PVar id, pann), bound, body) ->
     (* Let generalization occurs in this branch *)
     let st = increase_level st in
     gen_constraints st bound >>= fun ((_, bound_ty, _) as bound_typed, st) ->
     solve (Ok st.subst) st.constraints >>= fun subst ->
     let st = {st with subst = subst} in
     let ty = Monotype.apply st.subst bound_ty in
     let st = decrease_level st in
     let scheme = generalize st.current_level ty in
     let st = { st with env = extend [id] scheme st.env } in
     gen_constraints st body >>= fun ((_, ty, _) as body_typed, st) ->
     let pat_typed = (PVar(id, scheme), ty, pann) in
     Ok((ELet(pat_typed, bound_typed, body_typed), ty, ann), st)
  | Pretyped_tree.Let(pat, bound, body) ->
     (* Monomorphism restriction occurs in this branch *)
     walk_pattern st pat >>= fun ((_, pat_ty, _) as pat_typed, st) ->
     gen_constraints st bound >>= fun((_, bound_ty, _) as bound_typed, st) ->
     let st = {st with constraints = Unify(pat_ty, bound_ty)::st.constraints} in
     gen_constraints st body >>= fun((_, ty, _) as body_typed, st) ->
     Ok((ELet(pat_typed, bound_typed, body_typed), ty, ann), st)
  | Pretyped_tree.Literal lit ->
     begin match lit with
     | Pretyped_tree.Int i -> Ok ((ELit (Int i), TCon TInt, ann), st)
     | Pretyped_tree.Float f ->
        Ok ((ELit (Float f), TCon TFloat, ann), st)
     | Pretyped_tree.Char c ->
        Ok ((ELit (Char c), TCon TChar, ann), st)
     end
  | Pretyped_tree.Var id ->
     match IdMap.find_opt id st.env.map with
     | Some scheme ->
        let ty, st = instantiate st scheme in
        Ok((EVar id, ty, ann), st)
     | None -> Err "Unbound variable"
