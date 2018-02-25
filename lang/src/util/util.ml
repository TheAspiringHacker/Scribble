(** https://github.com/ocaml/ocaml/pull/1549 See infix operator workaround *)
let ($<) x f = f x
let (>$) f x = f x

module type FUNCTOR = sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end

module type APPLICATIVE = sig
  include FUNCTOR
  val (<*>) : ('a -> 'b) t -> 'a t -> 'b t
end

module type MONAD = sig
  include APPLICATIVE
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t
end

module Identity : MONAD with type 'a t = 'a = struct
  type 'a t = 'a
  let map f m = f m
  let (<*>) = map
  let (>>=) m f = f m
  let return x = x
end

module OptionT (M : MONAD) : MONAD with type 'a t = ('a option) M.t = struct
  type 'a t = ('a option) M.t

  let map (f : 'a -> 'b) (m : 'a t) =
    M.map (fun option ->
      match option with
      | Some x -> Some (f x)
      | None -> None) m

  let (<*>) f m =
    M.(>>=) f (fun f_opt ->
        match f_opt with
        | Some f ->
           M.map (fun x_opt ->
             match x_opt with
             | Some x -> Some (f x)
             | None -> None) m
        | None -> M.return None)

  let (>>=) m f = M.(>>=) m (fun option ->
    match option with
    | Some x -> f x
    | None -> M.return None)
  let return x = M.return @@ Some x
end

module Option = OptionT(Identity)

type ('a, 'b) result = Err of 'a | Ok of 'b

module ResultT (M : MONAD) (X : sig
  type t
end) : MONAD with type 'a t = ((X.t, 'a) result) M.t = struct
  type 'a t = ((X.t, 'a) result) M.t

  let map f m =
    M.map (fun result ->
      match result with
      | Ok x -> Ok (f x)
      | Err err -> Err err) m

  let (<*>) f m =
    M.(>>=) f (fun f_res ->
        match f_res with
        | Ok f ->
           M.map (fun x_res ->
               match x_res with
               | Ok x -> Ok (f x)
               | Err err -> Err err) m
        | Err err -> M.return @@ Err err)

  let (>>=) m f = m $<M.(>>=)>$ fun result ->
    match result with
    | Ok x -> f x
    | Err err -> M.return @@ Err err
  let return x = M.return @@ Ok x
end

module Result = ResultT(Identity)

module StateT (M : MONAD) (X : sig
  type t
end) : MONAD with type 'a t = X.t -> (('a * X.t) M.t) = struct
  type 'a t = X.t -> (('a * X.t) M.t)

  let map f f_st st =
    let m = f_st st in
    M.map (fun (a, st) -> (f a, st)) m

  let (<*>) applied arg st =
    let f_m = applied st in
    M.(>>=) f_m (fun (f, st) ->
        let x_m = arg st in
        M.map (fun (x, st) -> (f x, st)) x_m
      )

  let (>>=) m f st = M.(>>=) (m st) (fun (a, st) -> f a st)
  let return a st = M.return (a, st)
end

module State = StateT(Identity)
