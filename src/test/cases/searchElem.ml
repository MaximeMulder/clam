(*
open Clam
open Vars

let test ctx type' index (_: unit) =
  TypeSearch.search_proj ctx (TypeCheck.infer_elem_base index) type'

let name type' index expect =
  let type' = TypeDisplay.display type' in
  let index = string_of_int index in
  let expect = match expect with
  | Some expect -> TypeDisplay.display expect
  | None -> ""
  in
  "elem `" ^ type' ^ "` `" ^ index ^ "` `" ^ expect ^ "`"

let case type' index expect ctx =
  Case.make_case Case.type_option (name type' index expect) (test ctx type' index) expect

let case_var name bound case ctx =
  let bind = { Abt.name } in
  let ctx = TypeContext.add_bind_type ctx bind bound in
  let var = Type.var bind in
  case var ctx

let tests = [
  (* primitives *)
  case top 0 None;
  case unit 0 None;
  case bool 0 None;
  case bool 0 None;
  case string 0 None;

  (* tuples *)
  case (tuple [a]) 0 (Some a);
  case (tuple [a; b]) 1 (Some b);
  case (tuple []) 0 None;
  case (tuple [a]) 1 None;
  case (tuple [a; b]) 2 None;

  (* bottom *)
  case bot 0 (Some bot);
  case bot 1 (Some bot);

  (* vars *)
  case_var "A" (tuple []) (fun a -> case a 0 None);
  case_var "A" (tuple [c]) (fun a -> case a 0 (Some c));
  case_var "A" (tuple [c]) (fun a -> case_var "B" a (fun b -> case b 0 (Some c)));

  (* vars & bottom *)
  case_var "A" bot (fun a -> case a 0 (Some bot));
  case_var "A" bot (fun a -> case_var "B" a (fun b -> case b 0 (Some bot)));

  (* unions *)
  case (union [top; top]) 0 None;
  case (union [tuple [a]; top]) 0 None;
  case (union [top; tuple [a]]) 0 None;
  case (union [tuple []; tuple []]) 0 None;
  case (union [tuple [a]; tuple []]) 0 None;
  case (union [tuple []; tuple [a]]) 0 None;
  case (union [tuple [a]; tuple [a]]) 0 (Some a);
  case (union [tuple [a]; tuple [b]]) 0 (Some (union [a; b]));

  (* unions & bottom *)
  case (union [bot; bot]) 0 (Some bot);
  case (union [bot; tuple [a]]) 0 (Some a);
  case (union [tuple [a]; bot]) 0 (Some a);

  (* unions & intersections *)
  case (union [inter [tuple [a]; tuple [b]]; tuple [c]]) 0 (Some (union [inter [a; b]; c]));

  (* intersections *)
  case (inter [top; top]) 0 None;
  case (inter [tuple [a]; top]) 0 (Some a);
  case (inter [top; tuple [a]]) 0 (Some a);
  case (inter [tuple []; tuple []]) 0 None;
  case (inter [tuple [a]; tuple [a]]) 0 (Some a);
  case (inter [tuple [a]; tuple [b]]) 0 (Some (inter [a; b]));

  (* intersections & bottom *)
  case (inter [bot; bot]) 0 (Some bot);
  case (inter [bot; top]) 0 (Some bot);
  case (inter [top; bot]) 0 (Some bot);
  case (inter [unit; bool]) 0 (Some bot);
  case (inter [bool; unit]) 0 (Some bot);
  case (inter [tuple [a]; tuple []]) 0 (Some bot);
  case (inter [tuple []; tuple [a]]) 0 (Some bot);

  (* intersections & unions *)
  case (inter [union [tuple [a]; tuple [b]]; tuple [c]]) 0 (Some (union [inter [a; c]; inter [b; c]]));

  (* constructors *)
  case (abs "T" top (fun a -> (tuple [a]))) 0 None;
  case (app (abs "T" top id) (tuple [a])) 0 (Some a);
  case (app (abs "T" top (fun t -> (tuple [t]))) a) 0 (Some a);

  (* constructors & unions *)
  case (app (abs "T" top id) (union [tuple [a]; tuple []])) 0 None;
  case (app (abs "T" top id) (union [tuple [a]; tuple [b]])) 0 (Some (union [a; b]));

  (* constructors & intersections *)
  (* case (app (abs "T" top (fun t -> inter [tuple [t]; tuple [unit]])) top) 0 (Some unit);
  case (app (abs "T" top (fun t -> inter [tuple [unit]; tuple [t]])) top) 0 (Some unit);

  (* constructors & intersections & bottom *)
  case (app (abs "T" top id) (inter [unit; bool])) 0 (Some bot);
  case (app (abs "T" top (fun t -> inter [tuple [t]; tuple [unit]])) bool) 0 (Some bot);
  case (app (abs "T" top (fun t -> inter [tuple [unit]; tuple [t]])) bool) 0 (Some bot); *)
]
|> List.map (Util.apply ctx)
*)
