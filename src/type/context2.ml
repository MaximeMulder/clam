(**
  New super mega cool type context for type checking algorithm V2
*)

(** Fresh type variable, whose bounds can be tightened, and which can be reordered in the context. *)
type fresh = {
  bind: Abt.bind_type;
  level: int;
  lower: Node.type';
  upper: Node.type';
}

(** Rigid type variable, which have fixed bounds and order in the context. *)
type rigid = {
  bind: Abt.bind_type;
  lower: Node.type';
  upper: Node.type';
}

(** Typing context, which contains both fresh and rigid type variables. *)
type ctx = {
  level: int;
  freshs: fresh list;
  rigids: rigid list;
}

let empty = { level = 0; freshs = []; rigids = [] }

(* ACCESS TYPE VARIABLES *)

let update_fresh (var: fresh) ctx =
  let freshs = List.map (fun (old: fresh) -> if old.bind == var.bind then var else old) ctx.freshs in
  (), { ctx with freshs }

let with_param_fresh (param: Node.param) f ctx =
  let var = { bind = param.bind; level = ctx.level; lower = param.lower; upper = param.upper } in
  let ctx = { ctx with freshs = var :: ctx.freshs } in
  let x, ctx = f ctx in
  let ctx = { ctx with freshs = List.tl ctx.freshs } in
  x, ctx

let with_param_rigid (param: Node.param) f ctx =
  let var = { bind = param.bind; lower = param.lower; upper = param.upper } in
  let ctx = { ctx with rigids = var :: ctx.rigids } in
  let x, ctx = f ctx in
  let ctx = { ctx with rigids = List.tl ctx.rigids } in
  x, ctx

(** Type variable, either fresh or rigid. *)
type var =
| Fresh of fresh
| Rigid of rigid

(** Returns the fresh or rigid variable corresponding to a given bind in the context. *)
let get_var bind ctx =
  let fresh = List.find_opt (fun (var: fresh) -> var.bind == bind) ctx.freshs in
  let rigid = List.find_opt (fun (var: rigid) -> var.bind == bind) ctx.rigids in
  match fresh, rigid with
  | Some _, Some _ ->
    failwith ("Type variable `" ^ bind.name ^ "` present in both fresh and rigid variables.")
  | Some var, None ->
    Fresh var, ctx
  | None, Some var ->
    Rigid var, ctx
  | None, None ->
    failwith ("Type variable `" ^ bind.name ^ "` not found in the type context.")

(* REORDER FRESH VARIABLES *)

let rec cmp_level (left: Abt.bind_type) (right: Abt.bind_type) (vars: fresh list) =
  match vars with
  | [] ->
    failwith ("Fresh type variables `" ^ left.name ^ "` and `" ^ right.name ^ "` not found in the type context.")
  | var :: vars ->
    if var.bind == left then
      true
    else if var.bind == right then
      false
    else
      cmp_level left right vars

(** Compares the polymorphic level of two fresh type variables. *)
let cmp_level left right ctx =
  cmp_level left right ctx.freshs, ctx

let rec insert bind (other: fresh) vars =
  match vars with
  | [] ->
    [other]
  | var :: vars ->
    var :: if var.bind == bind then
      other :: vars
    else
      insert bind other vars

let rec reorder bind other (vars: fresh list) =
  match vars with
  | [] ->
    []
  | var :: vars ->
    var :: if var.bind == bind then
      vars
    else if var.bind == other then
      insert bind var vars
    else
      var :: reorder bind other vars

let reorder bind other ctx =
  let freshs = reorder bind other ctx.freshs in
  (), { ctx with freshs }

(* DISPLAY CONTEXT *)

let display_fresh (var: fresh) =
  var.bind.name
  ^ ": "
  ^ Display.display var.lower
  ^ " .. "
  ^ Display.display var.upper

let display_rigid (var: rigid) =
  var.bind.name
  ^ ": "
  ^ Display.display var.lower
  ^ " .. "
  ^ Display.display var.upper

let display ctx =
  let rigids = List.map display_rigid (List.rev ctx.rigids) |> String.concat ", " in
  let freshs = List.map display_fresh (List.rev ctx.freshs) |> String.concat ", " in
  (), rigids ^ "\n" ^ freshs

(* MONAD *)

module Monad = Util.Monad.Monad(Util.Monad.StateMonad(struct
  type s = ctx
end))

let get_context ctx = ctx, ctx