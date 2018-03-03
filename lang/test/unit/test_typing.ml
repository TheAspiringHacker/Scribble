open Typeck_types

let () = print_endline "Begin typing test."

let () =
  let open Pretyped_tree in
  let open Infer in
  let open Typeck_types in
  begin
      assert(unify Subst.empty (TCon TBool, TCon TInt)
             = Err(Cannot_unify(TCon TBool, TCon TInt)));
      begin match unify Subst.empty (TCon TBool, TCon TBool) with
      | Ok x -> assert (compare x Subst.empty = 0)
      | Err err -> assert(false)
      end;
      let subst = Subst.singleton 0 (Unbound(KStar, 0)) in
      begin match unify subst (TVar 0, TCon TInt) with
      | Ok x ->
         assert(Subst.compare compare x (Subst.singleton 0 (Link (TCon TInt)))
                = 0)
      | _ -> assert(false)
      end;
      let subst = Subst.singleton 12 (Unbound(KStar, 0)) in
      let subst = Subst.add 25 (Unbound(KStar, 1)) subst in
      begin match unify subst (TVar 12, TVar 25) with
      | Ok subst ->
         assert(Subst.find_opt 12 subst = Some(Link(TVar 25)));
         assert(Subst.find_opt 25 subst = Some(Unbound(KStar, 0)))
      | _ -> assert(false)
      end
  end

let () = print_endline "Typing test successful."
