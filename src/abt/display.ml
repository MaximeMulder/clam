open Util.Func
open Type

(**
  Direction in which the syntax of a type is recursive.
*)
type recursion =
  | N (* None *)
  | L (* Left *)
  | R (* Right *)
  | B (* Both *)

let return self string parent =
  let cond = match self, parent with
  | N, _ -> false
  | _, N -> false
  | L, L -> false
  | R, R -> false
  | _, _ -> true
  in
  if cond then
    "(" ^ string ^ ")"
  else
    string

(* CURRY *)

let rec curry_lam (lam: lam) =
  let param = lam.param in
  match lam.ret with
  | Lam lam ->
    let params, ret = curry_lam lam in
    param :: params, ret
  | _ ->
    [lam.param], lam.ret

let rec curry_univ (univ: univ) =
  let param = univ.param in
  match univ.ret with
  | Univ abs ->
    let params, ret = curry_univ abs in
    param :: params, ret
  | _ ->
    [univ.param], univ.ret

let rec curry_abs (abs: abs) =
  let param = abs.param in
  match abs.body with
  | Abs abs ->
    let params, ret = curry_abs abs in
    param :: params, ret
  | _ ->
    [abs.param], abs.body

let rec curry_app abs args =
  match abs with
  | App app ->
    curry_app app.abs (app.arg :: args)
  | _ ->
    abs, args

let curry_app (app: app) =
  curry_app app.abs [app.arg]

(* DISPLAY *)

let rec display type' =
  match type' with
  | Top _         -> return N "Top"
  | Bot _         -> return N "Bot"
  | Unit _        -> return N "Unit"
  | Bool _        -> return N "Bool"
  | Int _         -> return N "Int"
  | String _      -> return N "String"
  | Var var       -> return N var.bind.name
  | Tuple tuple   -> display_tuple tuple
  | Record record -> display_record record
  | Lam lam       -> display_lam lam
  | Univ univ     -> display_univ univ
  | Abs abs       -> display_abs abs
  | App app       -> display_app app
  | Rec rec'      -> display_rec rec'
  | Union union   -> display_union union
  | Inter inter   -> display_inter inter

and display_tuple tuple =
  let types = List.map (flip display N) tuple.elems in
  return N ("{" ^ (String.concat ", " types) ^ "}")

and display_record record =
  let attrs = List.of_seq (Util.NameMap.to_seq record.attrs)
    |> List.map snd
    |> List.map display_record_attr
  in
  return N ("{" ^ (String.concat ", " attrs) ^ "}")

and display_record_attr attr =
  attr.label ^ ": " ^ display attr.type' N

and display_lam lam =
  let params, ret = curry_lam lam in
  let params = List.map (flip display N) params in
  let type' = "(" ^ (String.concat ", " params) ^ ") -> " ^ (display ret R) in
  return R type'

and display_univ univ =
  let params, ret = curry_univ univ in
  let params = List.map display_param params in
  let type' = "[" ^ (String.concat ", " params) ^ "] -> " ^ (display ret R) in
  return R type'

and display_abs abs =
  let params, body = curry_abs abs in
  let params = List.map display_param params in
  let type' = "[" ^ (String.concat ", " params) ^ "] => " ^ (display body R) in
  return R type'

and display_app app =
  let abs, args = curry_app app in
  let args = List.map (flip display N) args in
  let type' = (display abs L) ^ "[" ^ (String.concat ", " args) ^ "]" in
  return L type'

and display_rec rec' =
  let body = display rec'.body R in
  return R (rec'.bind.name ^ ". " ^ body)

and display_union union =
  let left  = display union.left  L in
  let right = display union.right R in
  return B (left ^ " | " ^ right)

and display_inter inter =
  let left  = display inter.left  L in
  let right = display inter.right R in
  return B (left ^ " & " ^ right)

and display_param param =
  param.bind.name ^
  let lower = match param.lower with Bot _ -> false | _ -> true in
  let upper = match param.upper with Top _ -> false | _ -> true in
  (if lower || upper then ": " else "") ^
  (if lower then display param.lower N ^ " " else "") ^
  (if lower || upper then ".." else "") ^
  (if upper then " " ^ display param.upper N else "")

let display type' =
  display type' N
