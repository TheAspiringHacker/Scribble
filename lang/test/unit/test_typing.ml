open Typeck_types
open Util

let () = print_endline "Begin typing test."

let () =
  let open Pretyped_tree in
  let open Infer in
  let open Typeck_types in
  begin
      assert(unify Subst.empty (TCon TBool, TCon TInt)
             = Error (Cannot_unify(TCon TBool, TCon TInt)));
      begin match unify Subst.empty (TCon TBool, TCon TBool) with
      | Ok x -> assert (compare x Subst.empty = 0)
      | Error err -> assert(false)
      end;
      let subst = Subst.singleton 0 (Unbound{kind = KStar; level = 0}) in
      begin match unify subst (TVar 0, TCon TInt) with
      | Ok x ->
         assert(Subst.compare compare x (Subst.singleton 0 (Link (TCon TInt)))
                = 0)
      | _ -> assert(false)
      end;
      let subst = Subst.singleton 12 (Unbound{kind = KStar; level = 0}) in
      let subst = Subst.add 25 (Unbound{kind = KStar; level = 1}) subst in
      begin match unify subst (TVar 12, TVar 25) with
      | Ok subst ->
         assert(Subst.find_opt 12 subst = Some(Link(TVar 25)));
         assert(Subst.find_opt 25 subst
                = Some(Unbound{kind = KStar; level = 0}))
      | _ -> assert(false)
      end
  end

let () = print_endline "Typing test successful."
