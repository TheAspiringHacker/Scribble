(** https://github.com/ocaml/ocaml/pull/1549 See infix operator workaround *)
let ($<) x f = f x
let (>$) f x = f x

module type MONAD = sig
  type 'a m
  val (>>=) : 'a m -> ('a -> 'b m) -> 'b m
  val return : 'a -> 'a m
end

module Option : MONAD with type 'a m := 'a option = struct
  type 'a m = 'a option
  let (>>=) m f =
    match m with
    | Some x -> f x
    | None -> None
  let return x = Some x
end

type ('a, 'b) result = Err of 'a | Ok of 'b

module Result (X : sig
  type t
end) : MONAD with type 'a m := (X.t, 'a) result = struct
  type 'a m = (X.t, 'a) result
  let (>>=) (m : 'a m) (f : 'a -> 'b m) =
    match m with
    | Ok x -> f x
    | Err err -> Err err
  let return x = Ok x
end

module State (X : sig
  type t
end) : MONAD with type 'a m := X.t -> ('a * X.t) = struct
  type 'a m = X.t -> ('a * X.t)
  let (>>=) m f st =
    let (a, st) = m st in
    f a st
  let return a st = (a, st)
end
