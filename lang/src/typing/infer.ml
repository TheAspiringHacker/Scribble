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
module TypeResult = Result(struct type t = type_error end)
open TypeResult

type constrain = Unify of monotype * monotype

type tvar =
    (** An unbound type variable *)
  | Unbound of kind * int
    (** A type variable that has been unified *)
  | Link of monotype

type state = {
    (** The typing context *)
    mutable env : env;
    (** Counter used to generate type variable ids *)
    mutable gensym : int;
    (** List of type pairs to unify *)
    mutable constraints : constrain list;
    (** A map of integer ids to type variables *)
    tvars : (int, tvar) Hashtbl.t;
    (** Used to give type variables lifetimes *)
    mutable current_level : int;
  }

let fresh_var st kind = begin
    let id = st.gensym in
    Hashtbl.add st.tvars st.gensym (Unbound(kind, st.current_level));
    st.gensym <- st.gensym + 1;
    id
  end

let enter_level st = begin
    st.current_level <- st.current_level + 1
  end

let leave_level st = begin
    st.current_level <- st.current_level - 1
  end

let rec occurs st id level = function
  | TVar id1 ->
     begin match Hashtbl.find st.tvars id1 with
     | Unbound(_, level) ->
        if id = id1 then
          true
        else
          let id's_level = Hashtbl.find st.tvars id in
          let id1's_level = Hashtbl.find st.tvars id1 in
          (* Set level if necessary; I'm not sure if this is right so
             I will look for bugs here *)
          begin if id's_level < id1's_level then
            Hashtbl.replace st.tvars id1 id's_level
          end;
          false
     | Link ty -> occurs st id level ty
     end
  | TApp(constr, arg) -> (occurs st id level constr) && (occurs st id level arg)
  | _ -> false

let raise_if_occurs st id level ty = begin
    if occurs st id level ty then
      raise (Type_exn(Recursive_unification(id, ty)))
  end

let rec unify st = function
  | (TVar id0, TVar id1) when id0 = id1 -> ()
  | (TVar id, ty) | (ty, TVar id) ->
     begin match Hashtbl.find st.tvars id with
     | Unbound(_, level) ->
        raise_if_occurs st id level ty;
        Hashtbl.replace st.tvars id (Link ty)
     | Link ty1 -> unify st (ty, ty1)
     end
  | (TApp(t0, t1), TApp(t2, t3)) ->
     let () = unify st (t0, t2) in
     unify st (t1, t3)
  | (TCon c0, TCon c1) when c0 = c1 -> ()
  | (t0, t1) -> raise (Type_exn(Cannot_unify(t0, t1)))

module IntMap = Map.Make(struct type t = int let compare = compare end)

(** Turns a monotype into a polytype by quantifying over free tvars *)
let generalize st monotype =
  let rec helper ((map, list, count) as acc) = function
    | TApp(t0, t1) ->
       let acc, q0 = helper acc t0 in
       let acc, q1 = helper acc t1 in
       (acc, QApp(q0, q1))
    | TCon constr -> (acc, QCon constr)
    | TVar tvar ->
       match Hashtbl.find st.tvars tvar with
       | Unbound(kind, level) ->
          (* The tvar's level must be greater than the current level *)
          if level > st.current_level then
            (* Did we already quantify this? *)
            match IntMap.find_opt tvar map with
            (* Yes *) | Some x -> (acc, QBound x)
            (* No  *) | None ->
                         ((IntMap.add tvar count map, kind::list, count + 1),
                          QBound count)
          else
            (acc, QFree tvar)
       | Link ty -> helper acc ty
  in let ((_, list, _), qty) = helper (IntMap.empty, [], 0) monotype in
     (* Reverse the accumulated list (when accumulated, rightmost is head) *)
     {qvars = Array.of_list @@ List.rev list; quantitype = qty}

(** Turns a polytype into a monotype, replacing the qvars with fresh tvars *)
let instantiate st polytype =
  (* Generate an array of fresh type variables *)
  let ls = Array.fold_left
             (fun ls kind -> (fresh_var st kind)::ls) [] polytype.qvars
  in let array = Array.of_list @@ List.rev ls in
     (* Helper function that replaces qvars with tvars from the array *)
     let rec helper = function
       | QApp(t0, t1) -> TApp(helper t0, helper t1)
       | QBound idx -> TVar (array.(idx))
       | QFree tvar -> TVar tvar
       | QCon constr -> TCon constr
     in helper polytype.quantitype

(** Unify a list of monotype pairs *)
let solve st =
  let rec helper = function
    | [] -> ()
    | (Unify(t0, t1))::xs -> unify st (t0, t1); helper xs
  in helper st.constraints

(** Walk a pattern, introducing variables into the environment *)
let rec walk_pattern st (node, ann) =
  match node with
  | Pretyped_tree.PVar id ->
     let tvar = fresh_var st KStar in
     let poly = poly_of_mono (TVar tvar) in
     begin match add (Local id) poly st.env with
     | Some env ->
        st.env <- env;
        Ok(PVar(id, poly), (TVar tvar), ann)
     | None -> Err(Already_defined (Local id))
     end
  | Pretyped_tree.PPair(fst, snd) ->
      walk_pattern st fst >>= fun ((_, fst_ty, _)as fst) ->
      walk_pattern st snd >>= fun ((_, snd_ty, _) as snd) ->
      let ty = TApp(TApp(TCon TPair, fst_ty), snd_ty) in
      Ok(PPair(fst, snd), ty, ann)
  | Pretyped_tree.PUnit -> Ok(PUnit, TCon TUnit, ann)
  | Pretyped_tree.PWildcard ->
      let tvar = fresh_var st KStar in
      Ok(PWild, TVar tvar, ann)

(** Given a pretyped tree, return a typed tree and constraints *)
let rec gen_constraints st (node, ann) =
  try
    match node with
    | Pretyped_tree.App(f, x) ->
       gen_constraints st f >>= fun ((_, f_ty, _) as f) ->
       gen_constraints st x >>= fun ((_, x_ty, _) as x) ->
       let tv = TVar (fresh_var st KStar) in
       let t = TApp(TApp(TCon TFun, x_ty), tv) in
       st.constraints <- Unify(t, f_ty)::st.constraints;
       Ok(EApp(f, x), tv, ann)
    | Pretyped_tree.Lambda(pat, body) ->
       let env = st.env in
       st.env <- extend env;
       walk_pattern st pat >>= fun ((_, pat_ty, _) as pat) ->
       gen_constraints st body >>= fun ((_, body_ty, _) as body) ->
       st.env <- env;
       let ty = TApp(TApp(TCon TFun, pat_ty), body_ty) in
       Ok(ELam(pat, body), ty, ann)
    | Pretyped_tree.Let(bindings, body) ->
       let env = st.env in
       st.env <- extend env;
       let binding_opts = List.map (constrain_binding st) bindings in
       let bindings_opt =
         List.fold_left
           (fun acc next -> (map List.cons next) <*> acc)
           (Ok []) binding_opts in
       bindings_opt >>= fun bindings ->
       gen_constraints st body >>= fun ((_, ty, _) as body) ->
       st.env <- env;
       Ok(ELet(bindings, body), ty, ann)
    | Pretyped_tree.Literal lit ->
       begin match lit with
       | Pretyped_tree.Int i -> Ok(ELit (Int i), TCon TInt, ann)
       | Pretyped_tree.Float f -> Ok(ELit (Float f), TCon TFloat, ann)
       | Pretyped_tree.Char c -> Ok(ELit (Char c), TCon TChar, ann)
       end
    | Pretyped_tree.Var id ->
       match IdMap.find_opt id st.env.map with
       | Some scheme ->
          let ty = instantiate st scheme in
          Ok((EVar id), ty, ann)
       | None -> Err(Unbound_variable id)
  with
    Type_exn err -> Err err
and
  constrain_binding st = function
  | ((Pretyped_tree.PVar id, pann), expr) ->
     (* Let generalization occurs in this branch *)
     enter_level st;
     gen_constraints st expr >>= fun ((_, expr_ty, _) as expr) ->
     leave_level st;
     solve st;
     let scheme = generalize st expr_ty in
     begin match add (Local id) scheme st.env with
     | Some env ->
        st.env <- env;
        let pat = (PVar(id, scheme), expr_ty, pann) in
        Ok(pat, expr)
     | None -> Err(Already_defined (Local id))
     end
  | (pat, expr) ->
     (* Monomorphism restriction occurs in this branch *)
     walk_pattern st pat >>= fun ((_, pat_ty, _) as pat) ->
     gen_constraints st expr >>= fun ((_, expr_ty, _) as expr) ->
     st.constraints <- Unify(pat_ty, expr_ty)::st.constraints;
     Ok(pat, expr)
