module BindKey = struct
  type t = Abt.bind_expr

  let compare x y  = Stdlib.compare x.Abt.id y.Abt.id
end

module BindMap = Map.Make(BindKey)

type writer = string -> unit

type value =
| VUnit
| VBool    of bool
| VInt     of int
| VString  of string
| VTuple   of value list
| VRecord  of value Util.NameMap.t
| VExprAbs of abs_expr

and abs_expr =
  | VPrim of abs_expr_prim
  | VCode of abs_expr_code

and abs_expr_prim = context -> value

and abs_expr_code = {
  abs: Abt.expr_lam_abs;
  frame: frame
}

and context = { value: value; out: writer }

and frame = {
  parent: frame option;
  binds: value BindMap.t;
}

let rec compare left right =
  match (left, right) with
  | (VUnit, VUnit) ->
    true
  | (VBool left, VBool right) ->
    left = right
  | (VInt left, VInt right) ->
    left = right
  | (VString left, VString right) ->
    left = right
  | (VTuple lefts, VTuple rights) ->
    Util.compare_lists compare lefts rights
  | (VRecord lefts, VRecord rights) ->
    Util.compare_maps compare lefts rights
  | (VExprAbs (VPrim left), VExprAbs (VPrim right)) ->
    left = right
  | (VExprAbs (VCode left), VExprAbs (VCode right)) ->
    left.abs = right.abs
  | _ -> false

let value_bool value =
  match value with
  | VBool bool -> bool
  | _ -> RuntimeErrors.raise_value ()

let value_int value =
  match value with
  | VInt int -> int
  | _ -> RuntimeErrors.raise_value ()

let value_string value =
  match value with
  | VString string -> string
  | _ -> RuntimeErrors.raise_value ()
