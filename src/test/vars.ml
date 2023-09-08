open Clam.Model

let pos = prim_pos

let top    = prim_top
let bot    = prim_bot
let unit   = prim_unit
let bool   = prim_bool
let int    = prim_int
let char   = prim_char
let string = prim_string

let inline type' _ = type'

let var name type' =
  TypeVar { pos; param = { name; type' }}

let tuple elems =
  TypeTuple { pos; elems }

let record attrs =
  let attrs = attrs
    |> List.map (fun (name, type') -> (name, { pos; name; type' }))
    |> List.to_seq
    |> Clam.Utils.NameMap.of_seq in
  TypeRecord { pos; attrs }

let union left right =
  TypeUnion { pos; left; right }

let inter left right =
  TypeInter { pos; left; right }

let abs_expr params body =
  TypeAbsExpr { pos; params; body }

let abs_expr_type_0 body =
  TypeAbsExprType { pos; params = []; body = body }

let abs_expr_type_1 (name, type') body =
  let param = { name; type' } in
  let var = TypeVar { pos; param } in
  TypeAbsExprType { pos; params = [param]; body = body var }

let a = var "A" top
let b = var "B" top
let c = var "C" top
let d = var "D" top
