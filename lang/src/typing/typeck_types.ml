module IdMap = Map.Make(Ident)

type tycon = TFun | TPair | TUnit | TBool | TChar | TFloat | TInt

type kind = KStar | KFun

(** A monotype is a regular type *)
type monotype =
  | TApp of monotype * monotype
  | TCon of tycon
  | TVar of int

(** A quantitype is the body of a type scheme *)
type quantitype =
  | QApp of quantitype * quantitype
  | QBound of int
  | QFree of int
  | QCon of tycon

type 'a pred = string list * 'a

(* A polytype, or type scheme, is a generic type (quantifies type variables ) *)
type polytype = {
    qvars : kind array;
    quantitype : quantitype
  }

(** An environment is a mapping of variables to polytypes *)
type env = {
    map : polytype IdMap.t;
    parent : env option
  }

type type_error =
  | Already_defined of Ident.t
  | Cannot_unify of monotype * monotype
  | Recursive_unification of int * monotype
  | Unbound_variable of Ident.t
  | Kind_mismatch of int * kind * int * kind

exception Type_exn of type_error

let empty_env = {map = IdMap.empty; parent = None}

let rec lookup id env =
  match IdMap.find_opt id env.map with
  | Some x -> Some x
  | None ->
     match env.parent with
     | Some x -> lookup id x
     | None -> None

let add id scheme env =
  match IdMap.find_opt id env.map with
  | None -> Some { env with map = IdMap.add id scheme env.map }
  | _ -> None

let extend env = { map = IdMap.empty; parent = Some env }

let poly_of_mono mono =
  let rec helper = function
    | TApp(t0, t1) -> QApp(helper t0, helper t1)
    | TCon c -> QCon c
    | TVar tv -> QFree tv
  in {qvars = [||]; quantitype = helper mono}
