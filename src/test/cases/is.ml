open Vars

let test ctx left right (_: unit) =
  System.is ctx left right

let name left right expect =
  let left  = display left in
  let right = display right in
  let suffix = if expect then "" else "!" in
  "is" ^ suffix ^ " `" ^ left ^ "` `" ^ right ^ "`"

let case left right expect ctx =
  Case.make_case Case.bool (name left right expect) (test ctx left right) expect

let case_var name bound case expect ctx =
  let bind = { Abt.name } in
  let ctx = Context.add_bounds ctx bind Type.bot bound in
  let var = var bind in
  case var expect ctx

let tests = [
  (* bottom *)
  case bot bot;
  case_var "A" bot (fun a -> case a bot);
  case_var "A" bot (fun a -> case bot a);
  case_var "A" bot (fun a -> case_var "B" bot (fun b -> case a b));
  case_var "A" bot (fun a -> case_var "B" a (fun b -> case b bot));
  case_var "A" bot (fun a -> case_var "B" a (fun b -> case bot b));

  (* primitives *)
  case top top;
  case unit unit;
  case bool bool;
  case int int;
  case string string;
  case a a;

  (* unions *)
  case a (union [a; a]);
  case (union [a; a]) a;
  case (union [a; a]) (union [a; a]);
  case (union [a; b]) (union [a; b]);
  case (union [a; b]) (union [b; a]);
  case (union [a; union [b; c]]) (union [a; union [b; c]]);
  case (union [a; union [b; c]]) (union [union [a; b]; c]);
  case (union [union [a; b]; c]) (union [a; union [b; c]]);
  case (union [top; a]) top;
  case top (union [top; a]);
  case (union [a; union [b; ea]]) (union [a; b]);
  case (union [a; b]) (union [a; union [b; ea]]);

  (* intersections *)
  case a (inter [a; a]);
  case (inter [a; a]) a;
  case (inter [a; a]) (inter [a; a]);
  case (inter [a; b]) (inter [a; b]);
  case (inter [a; b]) (inter [b; a]);
  case (inter [top; a]) a;
  case a (inter [top; a]);
  case (inter [a; inter [b; ea]]) (inter [ea; b]);
  case (inter [ea; b]) (inter [a; inter [b; ea]]);

  (* distributivity *)
  case (union [inter [a; b]; inter [a; c]]) (inter [a; union [b; c]]);
  case (inter [a; union [b; c]]) (union [inter [a; b]; inter [a; c]]);

  (* meets *)
  case (inter [lam a c; lam b c]) (lam (union [a; b]) c);
  case (lam (union [a; b]) c) (inter [lam a c; lam b c]);
  case (inter [lam a b; lam a c]) (lam a (inter [b; c]));
  case (lam a (inter [b; c])) (inter [lam a b; lam a c]);

  (* universal abstractions *)
  case (univ "A" top (inline a)) (univ "A" top (inline a));
  case (univ "A" top id) (univ "A" top id);
  case (univ "A" top id) (univ "B" top id);
]
|> List.map (fun case -> case true ctx)

let tests_not = [
  (* top and bottom types *)
  case top bot;
  case bot top;
  case unit top;
  case top unit;
  case int bot;
  case bot int;

  (* primitives *)
  case unit bool;
  case bool int;
  case int string;
  case string unit;

  (* variables *)
  case a b;
  case ea a;
  case a ea;
  case ea fa;

  (* unions *)
  case a (union [a; b]);
  case (union [a; b]) a;
  case (union [top; a]) a;
  case a (union [top; a]);
  case (union [a; union [b; ea]]) (union [ea; b]);
  case (union [ea; b]) (union [a; union [b; ea]]);

  (* interesections *)
  case a (inter [a; b]);
  case (inter [a; b]) a;
  case (inter [top; a]) top;
  case top (inter [top; a]);
  case (inter [a; inter [b; ea]]) (inter [a; b]);
  case (inter [a; b]) (inter [a; inter [b; ea]]);

  (* meets *)
  case (inter [lam a c; lam b d]) (lam (union [a; b]) (inter [c; d]));
  case (lam (union [a; b]) (inter [c; d])) (inter [lam a c; lam b d]);

  (* ambiguous names *)
  case_var "A" top (fun a1 -> case_var "A" top (fun a2 -> case a1 a2));
  case (univ "A" top (inline a)) (univ "A" top id);
  case (univ "A" top id) (univ "A" top (inline a));

  (* type abstractions and variables *)
  case_var "T" (abs "X" top id) (fun t1 -> case_var "T" (abs "X" top id) (fun t2 -> case (app t1 top) (app t2 top)));
]
|> List.map (fun case -> case false ctx)
