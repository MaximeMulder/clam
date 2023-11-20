open Model
open Utils
open RuntimeValue

type writer = string -> unit

type context = {
  out_handler: writer;
  frame: frame;
}

let new_empty out_handler =
  { out_handler; frame = { parent = None; binds = BindMap.empty } }

let new_scope context binds =
  { context with frame = { parent = Some context.frame; binds } }

let new_frame context frame binds =
  { context with frame = { parent = Some frame; binds } }

let get_frame context =
  context.frame

let rec get_param param stack =
  match BindMap.find_opt (Model.BindExprParam param) stack.binds with
  | Some value -> value
  | None -> get_param param (Option.get stack.parent)

let rec get_var var stack =
  match BindMap.find_opt (Model.BindExprVar var) stack.binds with
  | Some value -> value
  | None -> get_var var (Option.get stack.parent)

module Reader = struct
  type r = context
end

open Monad.Monad(Monad.ReaderMonad(Reader))

let rec eval (expr: Model.expr) =
  match expr with
  | ExprUnit unit ->
    eval_unit unit
  | ExprBool bool ->
    eval_bool bool
  | ExprInt int ->
    eval_int int
  | ExprChar char ->
    eval_char char
  | ExprString string ->
    eval_string string
  | ExprBind bind ->
    eval_bind bind
  | ExprTuple tuple ->
    let* values = map_list eval tuple.elems in
    return (VTuple values)
  | ExprRecord record ->
    let* attrs = fold_list (fun map (attr: attr_expr) ->
      let* value = (eval attr.expr) in
      return (NameMap.add attr.name value map)
    ) NameMap.empty record.attrs in
    return (VRecord attrs)
  | ExprElem elem ->
    let* values = eval_tuple elem.expr in
    return (List.nth values elem.index)
  | ExprAttr attr ->
    let* attrs = eval_record attr.expr in
    return (NameMap.find attr.name attrs)
  | ExprPreop preop ->
    eval_preop preop
  | ExprBinop binop ->
    eval_binop binop
  | ExprAscr ascr ->
    eval ascr.expr
  | ExprIf if' ->
    let* cond = eval_value_bool if'.cond in
    if cond then eval if'.then' else eval if'.else'
  | ExprAbs abs ->
    let* frame = get_frame in
    return (VExprAbs { abs; frame })
  | ExprApp app ->
    eval_expr_app app
  | ExprTypeAbs abs ->
    let* frame = get_frame in
    return (VTypeAbs { abs; frame })
  | ExprTypeApp app ->
    eval_type_app app.expr
  | ExprStmt stmt ->
    eval_stmt stmt

and eval_unit unit =
  let _ = unit.pos in
  return VUnit

and eval_bool bool =
  return (VBool bool.value)

and eval_int int =
  return (VInt int.value)

and eval_char char =
  return (VChar char.value)

and eval_string string =
  return (VString string.value)

and eval_bind bind context =
  match (Option.get !(bind.bind)) with
  | BindExprDef def -> eval def.expr (new_empty context.out_handler)
  | BindExprParam param -> get_param param context.frame
  | BindExprPrint -> VPrint
  | BindExprVar var -> get_var var context.frame

and eval_expr_app app context =
  let value = eval app.expr context in
  match value with
  | VPrint -> eval_expr_app_print app.arg context
  | VExprAbs abs -> eval_expr_app_abs abs app.arg context
  | _ -> RuntimeErrors.raise_value ()

and eval_expr_app_print arg context =
  let value = eval arg context in
  let string = RuntimeDisplay.display value in
  let _ = context.out_handler string in
  VUnit

and eval_expr_app_abs abs arg context =
  let value = eval arg context in
  let binds = BindMap.singleton (Model.BindExprParam abs.abs.param) value in
  let context = new_frame context abs.frame binds in
  eval abs.abs.body context

and eval_type_app expr =
  let* value = eval expr in
  match value with
  | VTypeAbs abs ->
    eval_type_app_abs abs
  | _ ->
    RuntimeErrors.raise_value ()

and eval_type_app_abs abs context =
  let context = new_frame context abs.frame BindMap.empty in
  eval abs.abs.body context

and eval_preop preop =
  let expr = preop.expr in
  match preop.op with
  | "+" ->
    let* value = eval_value_int expr in
    return (VInt value)
  | "-" ->
    let* value = eval_value_int expr in
    return (VInt ~- value)
  | "!" ->
    let* value = eval_value_bool expr in
    return (VBool (not value))
  | _ -> RuntimeErrors.raise_operator preop.op

and eval_binop binop =
  let left = binop.left in
  let right = binop.right in
  match binop.op with
  | "+"  ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VInt (left + right))
  | "-"  ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VInt (left - right))
  | "*"  ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VInt (left * right))
  | "/"  ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VInt (left / right))
  | "%"  ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VInt (left mod right))
  | "++" ->
    let* left = eval_value_string left in
    let* right = eval_value_string right in
    return (VString (left ^ right))
  | "==" ->
    let* left = eval left in
    let* right = eval right in
    return (VBool (RuntimeValue.compare left right))
  | "!=" ->
    let* left = eval left in
    let* right = eval right in
    return (VBool (Bool.not (RuntimeValue.compare left right)))
  | "<" ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VBool (left < right))
  | ">" ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VBool (left > right))
  | "<=" ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VBool (left <= right))
  | ">=" ->
    let* left = eval_value_int left in
    let* right = eval_value_int right in
    return (VBool (left >= right))
  | "|" ->
    let* left = eval_value_bool left in
    let* right = eval_value_bool right in
    return (VBool (left || right))
  | "&" ->
    let* left = eval_value_bool left in
    let* right = eval_value_bool right in
    return (VBool (left && right))
  | _ -> RuntimeErrors.raise_operator binop.op

and eval_record (expr: Model.expr) =
  let* value = eval expr in
  match value with
  | VRecord attrs -> return attrs
  | _ -> RuntimeErrors.raise_value ()

and eval_stmt stmt context =
  let context = match stmt.stmt with
  | StmtVar (var, _, expr) ->
    let value = eval expr context in
    new_scope context (BindMap.singleton (BindExprVar var) value)
  | StmtExpr expr ->
    let _ = eval expr context in
    context
  in
  eval stmt.expr context

and eval_value_bool (expr: Model.expr) =
  let* value = eval expr in
  match value with
  | VBool bool -> return bool
  | _ -> RuntimeErrors.raise_value ()

and eval_value_int (expr: Model.expr) =
  let* value = eval expr in
  match value with
  | VInt int -> return int
  | _ -> RuntimeErrors.raise_value ()

and eval_value_string (expr: Model.expr) =
  let* value = eval expr in
  match value with
  | VString string -> return string
  | _ -> RuntimeErrors.raise_value ()

and eval_tuple (expr: Model.expr) =
  let* value = eval expr in
  match value with
  | VTuple values -> return values
  | _ -> RuntimeErrors.raise_value ()

let eval_def def stdout =
  eval def.expr (new_empty stdout)

