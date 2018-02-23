(** https://github.com/ocaml/ocaml/pull/1549 See infix operator workaround *)
let ($<) x f = f x
let (>$) f x = f x

module type MONAD = sig
  type 'a m
  val (>>=) : 'a m -> ('a -> 'b m) -> 'b m
  val return : 'a -> 'a m
end

module Identity : MONAD with type 'a m = 'a = struct
  type 'a m = 'a
  let (>>=) m f = f m
  let return x = x
end

module OptionT (M : MONAD) : MONAD with type 'a m = ('a option) M.m = struct
  type 'a m = ('a option) M.m
  let (>>=) m f = M.(>>=) m (fun option ->
    match option with
    | Some x -> f x
    | None -> M.return None)
  let return x = M.return @@ Some x
end

module Option : MONAD with type 'a m = 'a option = struct
  type 'a m = 'a option
  let (>>=) m f =
    match m with
    | Some x -> f x
    | None -> None
  let return x = Some x
end

type ('a, 'b) result = Err of 'a | Ok of 'b

module ResultT (M : MONAD) (X : sig
  type t
end) : MONAD with type 'a m = ((X.t, 'a) result) M.m = struct
  type 'a m = ((X.t, 'a) result) M.m
  let (>>=) m f = m $<M.(>>=)>$ fun result ->
    match result with
    | Ok x -> f x
    | Err err -> M.return @@ Err err
  let return x = M.return @@ Ok x
end

module Result = ResultT(Identity)

module State (X : sig
  type t
end) : MONAD with type 'a m = X.t -> ('a * X.t) = struct
  type 'a m = X.t -> ('a * X.t)
  let (>>=) m f st =
    let (a, st) = m st in
    f a st
  let return a st = (a, st)
end
