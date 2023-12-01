open Model
open RuntimeValue

let pos = {
  Lexing.pos_fname = "primitives.clam";
  Lexing.pos_lnum = 0;
  Lexing.pos_bol = 0;
  Lexing.pos_cnum = 0;
}

let top    = TypeTop    { pos }
let bot    = TypeBot    { pos }
let unit   = TypeUnit   { pos }
let bool   = TypeBool   { pos }
let int    = TypeInt    { pos }
let char   = TypeChar   { pos }
let string = TypeString { pos }

type primitive = {
  bind: bind_expr;
  name: string;
  type': type';
  value: value;
}

let make_primitives primitives =
  let (_, primitives) = List.fold_left (fun (id, res) (name, type', value) ->
    id - 1, { bind = BindExprPrim id; name; type'; value } :: res
  ) (-1, []) primitives in
  primitives

let unary name value ret prim =
  (name,
  TypeAbsExpr { pos; param = value; body = ret },
  VExprAbs (VPrim (fun { value; out } -> prim value out)))

let binary name left right ret prim =
  (
    name,
    TypeAbsExpr { pos; param = left; body = TypeAbsExpr { pos; param = right; body = ret }},
    VExprAbs (VPrim (fun { value; _ } ->
      let left = value in
      VExprAbs (VPrim (fun { value; _ } ->
        let right = value in
        prim left right
      ))
    ))
  )

let primitives = make_primitives [
  unary "print" top unit (fun value out ->
    let string = RuntimeDisplay.display value in
    let _ = out string in
    VUnit);
  unary "__pos__" int int (fun value _ ->
    let int = value_int value in
    (VInt int));
  unary "__neg__" int int (fun value _ ->
    let int = value_int value in
    (VInt (-int)));
  unary "__not__" bool bool (fun value _ ->
    let bool = value_bool value in
    (VBool (not bool)));
  binary "__add__" int int int (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VInt (left + right));
  binary "__sub__" int int int (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VInt (left - right));
  binary "__mul__" int int int (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VInt (left * right));
  binary "__div__" int int int (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VInt (left / right));
  binary "__mod__" int int int (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VInt (left mod right));
  binary "__concat__" string string string (fun left right ->
    let left  = value_string left  in
    let right = value_string right in
    VString (left ^ right));
  binary "__eq__" top top bool (fun left right ->
    VBool (compare left right));
  binary "__ne__" top top bool (fun left right ->
    VBool (not (compare left right)));
  binary "__lt__" int int bool (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VBool (left < right));
  binary "__gt__" int int bool (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VBool (left > right));
  binary "__le__" int int bool (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VBool (left <= right));
  binary "__ge__" int int bool (fun left right ->
    let left  = value_int left  in
    let right = value_int right in
    VBool (left >= right));
  binary "__and__" bool bool bool (fun left right ->
    let left  = value_bool left  in
    let right = value_bool right in
    VBool (left && right));
  binary "__or__" bool bool bool (fun left right ->
    let left  = value_bool left  in
    let right = value_bool right in
    VBool (left || right));
]

let binds = List.map (fun primitive -> primitive.name, primitive.bind) primitives

let types = List.map (fun primitive -> primitive.bind, primitive.type') primitives

let values = List.map (fun primitive -> primitive.bind, primitive.value) primitives