open Util

let incr x = x + 1

let () = print_endline "Begin util test.";;

let () =
  let open Option in (
      assert ((map incr (Some 0)) = (Some 1));
      assert ((map incr None) = None);
      assert (((Some incr) <*> (Some 0)) = (Some 1));
      assert (((Some incr) <*> None) = None);
      assert ((None <*> (Some 0)) = None);
      assert ((None <*> None) = None);
      assert (((Some 0) >>= fun x -> Some (incr x)) = (Some 1));
      assert ((None >>= fun x -> Some (incr x)) = None)
    )

let () =
  let module IntResult = Result(struct type t = int end) in
  let open IntResult in (
      assert ((map incr (Ok 0)) = (Ok 1));
      assert ((map incr (Error 0)) = (Error 0));
      assert (((Ok incr) <*> (Ok 0)) = (Ok 1));
      assert (((Ok incr) <*> (Error 0)) = (Error 0));
      assert (((Error 0) <*> (Ok 0)) = (Error 0));
      assert (((Error 0) <*> (Error 1)) = (Error 0));
      assert (((Ok 0) >>= fun x -> Ok (incr x)) = (Ok 1));
      assert (((Error 0) >>= fun x -> Ok (incr x)) = (Error 0))
    )

let () = print_endline "Util test successful."
