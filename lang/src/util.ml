module type MONAD = sig
  type 'a m
  val bind : 'a m -> ('a -> 'b m) -> 'b m
  val return : 'a -> 'a m
  val (>>=) : 'a m -> ('a -> 'b m) -> 'b m
  val (>>) : 'a m -> 'b m -> 'b m
end

module Option : MONAD with type 'a m = 'a option = struct
  type 'a m = 'a option
  let bind m f =
    match m with
    | Some x -> f x
    | None -> None
  let return x = Some x
  let (>>=) = bind
  let (>>) m0 m1 = m1
end

type ('a, 'b) result = Err of 'a | Ok of 'b

module Result (X : sig
  type t
end) : MONAD with type 'a m := (X.t, 'a) result = struct
  type 'a m = (X.t, 'a) result
  let bind (m : 'a m) (f : 'a -> 'b m) =
    match m with
    | Ok x -> f x
    | Err err -> Err err
  let return x = Ok x
  let (>>=) = bind
  let (>>) m0 m1 = m1
end
