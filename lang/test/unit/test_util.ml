open Util

let incr x = x + 1

let _ = print_endline "Begin util test.";;

let _ =
  let open Option in (
      assert ((map incr (Some 0)) = (Some 1));
      assert ((map incr None) = None);
      assert (((Some incr) <*> (Some 0)) = (Some 1));
      assert (((Some incr) <*> None) = None);
      assert ((None <*> (Some 0)) = None);
      assert ((None <*> None) = None);
      assert (((Some 0) >>= (fun x -> Some (incr x))) = (Some 1));
      assert ((None >>= (fun x -> Some incr)) = None)
    )

let _ =
  let module IntResult = Result(struct type t = int end) in
  let open IntResult in (
      assert ((map incr (Ok 0)) = (Ok 1));
      assert ((map incr (Err 0)) = (Err 0));
      assert (((Ok incr) <*> (Ok 0)) = (Ok 1));
      assert (((Ok incr) <*> (Err 0)) = (Err 0));
      assert (((Err 0) <*> (Ok 0)) = (Err 0));
      assert (((Err 0) <*> (Err 1)) = (Err 0));
      assert (((Ok 0) >>= (fun x -> Ok (incr x))) = (Ok 1));
      assert (((Err 0) >>= (fun x -> Ok (incr x))) = (Err 0))
    )

let _ = print_endline "Util test successful.";;
