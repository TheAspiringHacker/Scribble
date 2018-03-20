(**
This is the type inferencer. The current steps are to
  0. Generate constraints and a typed tree from a pretyped tree
  1. Solve the constraints at the let bindings
  2. Check for unquantified type variables and return a core AST

This type inferencer uses the optimization of "levels" from the OCaml
type inferencer to determine which type variables to quantify. See
http://okmij.org/ftp/ML/generalization.html.
 *)

open Typeck_types
open Typed_tree
open Util
module TypeResult = Result(struct type t = type_error end)
open TypeResult
module IntMap = Map.Make(struct type t = int let compare = compare end)
module Subst = IntMap

type constrain = Unify of monotype * monotype

type tvar =
    (** An unbound type variable *)
  | Unbound of {kind : kind; level : int}
    (** A type variable that has been unified *)
  | Link of monotype
    (** A quantified type variable *)
  | Quantified of {level : int; index : int}

type substitution = tvar Subst.t

type state = {
    (** The typing context *)
    mutable env : env;
    (** Counter used to generate type variable ids *)
    mutable gensym : int;
    (** List of type pairs to unify *)
    mutable constraints : constrain list;
    (** A map of integer ids to type variables *)
    mutable subst : substitution;
    (** Used to give type variables lifetimes *)
    mutable current_level : int;
  }

let empty_subst = Subst.empty

let fresh_var st kind = begin
    st.subst <- Subst.add
                  st.gensym
                  (Unbound {kind = kind; level = st.current_level})
                  st.subst;
    st.gensym <- st.gensym + 1;
    st.gensym - 1
  end

let enter_level st = begin
    st.current_level <- st.current_level + 1
  end

let leave_level st = begin
    st.current_level <- st.current_level - 1
  end

let rec occurs_check subst id level = function
  | TVar id1 ->
     begin match Subst.find id1 subst with
     | Unbound{level} ->
        if id = id1 then
          None
        else
          let id's_level = Subst.find id subst in
          let id1's_level = Subst.find id1 subst in
          (* Set level if necessary; I'm not sure if this is right so
             I will look for bugs here *)
          if id's_level < id1's_level then
            Some (Subst.add id1 id's_level subst)
          else
            Some subst
     | Link ty -> occurs_check subst id level ty
     | Quantified _ -> Some subst
     end
  | TApp(constr, arg) ->
     Option.(>>=) (occurs_check subst id level constr) (fun subst ->
       occurs_check subst id level arg)
  | _ -> Some subst

let rec unify subst = function
  | (TVar id0, TVar id1) when id0 = id1 -> Ok subst
  | (TVar id, ty) | (ty, TVar id) ->
     begin match Subst.find id subst with
     | Unbound{level; _} ->
        begin match occurs_check subst id level ty with
        | Some subst -> Ok (Subst.add id (Link ty) subst)
        | None -> Err(Recursive_unification(id, ty))
        end
     | Link ty1 -> unify subst (ty, ty1)
     | Quantified _ -> Err (Cannot_unify(TVar id, ty))
     end
  | (TApp(t0, t1), TApp(t2, t3)) ->
     unify subst (t0, t2) >>= fun subst -> unify subst (t1, t3)
  | (TCon c0, TCon c1) when c0 = c1 -> Ok subst
  | (t0, t1) -> Err (Cannot_unify(t0, t1))

(** Turns a monotype into a polytype by quantifying over free tvars *)
let generalize st monotype =
  (* map is map of tvar ids to indices in polytype *)
  (* list is list of kinds *)
  (* count is counter for fresh indices *)
  let rec helper ((map, list, count) as acc) = function
    | TApp(t0, t1) ->
       let acc = helper acc t0 in
       let acc = helper acc t1 in
       acc
    | TCon constr -> acc
    | TVar tvar ->
       match Subst.find tvar st.subst with
       | Unbound {kind; level} ->
          (* The tvar's level must be GREATER than the current level *)
          if level > st.current_level then
            (* Did we already quantify this? *)
            match Subst.find_opt tvar map with
            | Some _ -> acc
            | None ->
               (let quantified =
                  Quantified {level = st.current_level; index = count}
                in st.subst <- Subst.add tvar quantified st.subst);
               (Subst.add tvar count map, kind::list, count + 1)
          else
            acc
       | Link ty -> helper acc ty
       | Quantified _ -> acc
  in let (_, list, _) = helper (IntMap.empty, [], 0) monotype in
     { qvars = Array.of_list list
     ; level = st.current_level
     ; quantitype = monotype }

(** Turns a polytype into a monotype, replacing the qvars with fresh tvars *)
let instantiate st polytype =
  (* Generate an array of fresh type variables *)
  let ls = Array.fold_left
             (fun ls kind -> (fresh_var st kind)::ls) [] polytype.qvars
  in let array = Array.of_list ls in
     (* Helper function that replaces qvars with tvars from the array *)
     let rec helper = function
       | TApp(t0, t1) -> TApp(helper t0, helper t1)
       | TVar idx ->
          begin match Subst.find idx st.subst with
          | Unbound {kind; level} -> TVar level
          | Link ty -> helper ty
          (** Instantiate qvar *)
          | Quantified {level; index} when level = polytype.level ->
             TVar(array.(index))
          (** Don't instantiate qvar *)
          | Quantified _ -> TVar idx
          end
       | x -> x
     in helper polytype.quantitype

(** Unify a list of monotype pairs *)
let solve subst constraints =
  List.fold_left
    (fun acc (Unify(t0, t1)) -> acc >>= fun subst -> unify subst (t0, t1))
    (Ok subst) constraints

(** Walk a pattern, introducing variables into the environment *)
let rec walk_pattern st (node, ann) =
  match node with
  | Pretyped_tree.PVar id ->
     let tvar = fresh_var st KStar in
     let poly = poly_of_mono st.current_level (TVar tvar) in
     begin match add (Local id) poly st.env with
     | Some env ->
        st.env <- env;
        Ok {node = PVar(id, poly); ty = TVar tvar; ann = ann}
     | None -> Err(Already_defined (Local id))
     end
  | Pretyped_tree.PPair(fst, snd) ->
      walk_pattern st fst >>= fun fst ->
      walk_pattern st snd >>= fun snd ->
      let ty = TApp(TApp(TCon TPair, fst.ty), snd.ty) in
      Ok {node = PPair(fst, snd); ty = ty; ann}
  | Pretyped_tree.PUnit -> Ok{node = PUnit; ty = TCon TUnit; ann = ann}
  | Pretyped_tree.PWildcard ->
      let tvar = fresh_var st KStar in
      Ok {node = PWild; ty = TVar tvar; ann = ann}

(** Given a pretyped tree, return a typed tree and constraints *)
let rec gen_constraints st (node, ann) =
  match node with
  | Pretyped_tree.EApp(f, x) ->
     gen_constraints st f >>= fun f ->
     gen_constraints st x >>= fun x ->
     let tv = TVar (fresh_var st KStar) in
     let t = TApp(TApp(TCon TFun, x.ty), tv) in
     st.constraints <- Unify(t, f.ty)::st.constraints;
     Ok {node = EApp(f, x); ty = tv; ann = ann}
  | Pretyped_tree.ELam(pat, body) ->
     let env = st.env in
     st.env <- extend env;
     walk_pattern st pat >>= fun pat ->
     gen_constraints st body >>= fun body ->
     st.env <- env;
     let ty = TApp(TApp(TCon TFun, pat.ty), body.ty) in
     Ok {node = ELam(pat, body); ty = ty; ann = ann}
  | Pretyped_tree.ELet(bindings, body) ->
     let env = st.env in
     st.env <- extend env;
     let binding_ress = List.map (constrain_binding st) bindings in
     let f acc next = List.cons <$> next <*> acc in
     let bindings_res = List.fold_left f (Ok []) binding_ress in
     bindings_res >>= fun bindings ->
     gen_constraints st body >>= fun body ->
     st.env <- env;
     Ok {node = ELet(bindings, body); ty = body.ty; ann = ann}
  | Pretyped_tree.ELit lit ->
     begin match lit with
     | Pretyped_tree.Int i ->
        Ok {node = ELit (Int i); ty = TCon TInt; ann = ann}
     | Pretyped_tree.Float f ->
        Ok {node = ELit (Float f); ty = TCon TFloat; ann = ann}
     | Pretyped_tree.Char c ->
        Ok {node = ELit (Char c); ty = TCon TChar; ann = ann}
     end
  | Pretyped_tree.EMat(test, cases) ->
     gen_constraints st test >>= fun test ->
     let helper st (pat, pred_opt, expr) =
       walk_pattern st pat >>= fun pat ->
       gen_constraints st expr >>= fun expr ->
       let pred_res_opt = Option.map (gen_constraints st) pred_opt in
       match pred_res_opt with
       | Some result ->
          result >>= fun pred ->
          st.constraints <- Unify(pred.ty, TCon TBool)::st.constraints;
          Ok(pat, Some pred, expr)
       | None -> Ok(pat, None, expr) in
     let case_ress = List.map (helper st) cases in
     let f acc next = List.cons <$> next <*> acc in
     let cases_res = List.fold_left f (Ok []) case_ress in
     cases_res >>= fun cases ->
     let tvar = TVar (fresh_var st KStar) (* Tvar is this form's type *) in
     List.iter
       (fun (pat, _, expr) ->
         st.constraints <-
           Unify(pat.ty, test.ty)::Unify(expr.ty, tvar)::st.constraints)
       cases;
     Ok {node = EMat(test, cases); ty = tvar; ann = ann}
  | Pretyped_tree.EVar id ->
     match IdMap.find_opt id st.env.map with
     | Some scheme ->
        let ty = instantiate st scheme in
        Ok {node = EVar id; ty = ty; ann = ann}
     | None -> Err(Unbound_variable id)

and constrain_binding st = function
  | ((Pretyped_tree.PVar id, pann), expr) ->
     (* Let generalization occurs in this branch *)
     enter_level st;
     gen_constraints st expr >>= fun expr ->
     leave_level st;
     solve st.subst st.constraints >>= fun subst ->
     st.subst <- subst;
     (* At the point of generalization, all tvars to quantify have a GREATER
        level than the current level *)
     let scheme = generalize st expr.ty in
     begin match add (Local id) scheme st.env with
     | Some env ->
        st.env <- env;
        let pat = {node = PVar(id, scheme); ty = expr.ty; ann = pann} in
        Ok(pat, expr)
     | None -> Err(Already_defined (Local id))
     end
  | (pat, expr) ->
     (* Monomorphism restriction occurs in this branch *)
     walk_pattern st pat >>= fun pat ->
     gen_constraints st expr >>= fun expr ->
     st.constraints <- Unify(pat.ty, expr.ty)::st.constraints;
     Ok(pat, expr)

(** Kind to kind *)
let rec ast_of_kind = function
  | KStar -> Ast.KStar
  | KFun(x, y) -> Ast.KFun(ast_of_kind x, ast_of_kind y)

(** Convert internal typechecker type representation into AST representation *)
let rec ast_of_type st = function
  | TApp(f, x) -> Ast.TApp(ast_of_type st f, ast_of_type st x)
  | TCon constr ->
     Ast.TCon
       begin match constr with
       | TFun -> Ast.TFun
       | TPair -> Ast.TPair
       | TUnit -> Ast.TUnit
       | TBool -> Ast.TBool
       | TChar -> Ast.TChar
       | TFloat -> Ast.TFloat
       | TInt -> Ast.TInt
       end
  | TVar tvar ->
     match Subst.find tvar st.subst with
       (* If the tvar is unassigned, make it an Int *)
     | Unbound {kind; level} -> begin
         st.subst <- Subst.add tvar (Link (TCon TInt)) st.subst;
         Ast.TCon Ast.TInt
       end
     | Link ty -> ast_of_type st ty
     | Quantified {level; index} -> Ast.TVar(level, index)

(** Convert typed tree pattern type to AST pattern type *)
let rec ast_of_pattern st {node; ty; ann} =
  Ast.{ node = begin match node with
               | Typed_tree.PPair(fst, snd) ->
                  Ast.PPair(ast_of_pattern st fst, ast_of_pattern st snd)
               | PUnit -> Ast.PUnit
               | PVar(str_id, polyty) -> Ast.PVar(str_id)
               | PWild -> Ast.PWild
               end
      ; ty = ast_of_type st ty
      ; ann = ann }

(** Convert expr to AST *)
let rec ast_of_expr st {node; ty; ann} =
  Ast.{ node = begin match node with
               | Typed_tree.EApp(f, x) ->
                  Ast.EApp(ast_of_expr st f, ast_of_expr st x)
               | ELam(pat, body) ->
                  Ast.ELam(ast_of_pattern st pat, ast_of_expr st body)
               | ELet(bindings, body) ->
                  Ast.ELet(ast_of_bindings st bindings, ast_of_expr st body)
               | ELit lit -> Ast.ELit
                               begin match lit with
                               | Typed_tree.Char c -> Ast.Char c
                               | Typed_tree.Float f -> Ast.Float f
                               | Typed_tree.Int i -> Ast.Int i
                              end
               | EMat(test, cases) ->
                  Ast.EMat(ast_of_expr st test, List.map (ast_of_case st) cases)
               | EVar ident -> Ast.EVar ident
               end
      ; ty = ast_of_type st ty
      ; ann = ann }

and ast_of_bindings st bindings =
  List.map (fun (pat, expr) ->
      (ast_of_pattern st pat, ast_of_expr st expr)) bindings

and ast_of_case st (pat, expr_opt, expr) =
    (ast_of_pattern st pat,
     Option.map (ast_of_expr st) expr_opt,
     ast_of_expr st expr)
