open Type

let rec validate_proper ctx type' =
  let type'' = validate ctx type' in
  if TypeKind.get_kind ctx type'' <> TypeKind.Type then
    TypeError.validate_proper type'
  else
    type''

and validate ctx (type': Model.type') =
  match type' with
  | TypeTop    _ -> base Top
  | TypeBot    _ -> base Bot
  | TypeUnit   _ -> base Unit
  | TypeBool   _ -> base Bool
  | TypeInt    _ -> base Int
  | TypeChar   _ -> base Char
  | TypeString _ -> base String
  | TypeVar var ->
    base (Var { bind = var.bind })
  | TypeTuple tuple ->
    validate_tuple ctx tuple
  | TypeRecord record ->
    validate_record ctx record
  | TypeInter inter ->
    validate_inter ctx inter
  | TypeUnion union ->
    validate_union ctx union
  | TypeAbsExpr abs ->
    validate_abs_expr ctx abs
  | TypeAbsExprType abs ->
    validate_abs_type_expr ctx abs
  | TypeAbs abs ->
    validate_abs ctx abs
  | TypeApp app ->
    validate_app ctx app

and validate_tuple ctx tuple =
  let elems = List.map (validate_proper ctx) tuple.elems in
  base (Tuple { elems })

and validate_record ctx record =
  let attrs = Utils.NameMap.map (validate_record_attr ctx) record.attrs in
  base (Record { attrs })

and validate_record_attr ctx attr =
  let type' = validate_proper ctx attr.type' in
  { name = attr.name; type' }

and validate_inter ctx inter =
  let left  = validate ctx inter.left  in
  let right = validate ctx inter.right in
  if TypeKind.get_kind ctx left <> TypeKind.get_kind ctx right then
    TypeError.validate_inter_kind inter
  else
  Typing2.meet ctx left right

and validate_union ctx union =
  let left  = validate ctx union.left  in
  let right = validate ctx union.right in
  if TypeKind.get_kind ctx left <> TypeKind.get_kind ctx right then
    TypeError.validate_union_kind union
  else
  Typing2.join ctx left right

and validate_abs_expr ctx abs =
  let param = validate_proper ctx abs.param in
  let ret = validate_proper ctx abs.body in
  base (AbsExpr { param; ret })

and validate_abs_type_expr ctx abs =
  let param = validate_param ctx abs.param in
  let ret = validate_proper ctx abs.body in
  base (AbsTypeExpr { param; ret })

and validate_abs ctx abs =
  let param = validate_param ctx abs.param in
  let body = validate ctx abs.body in
  base (Abs { param; body })

and validate_app ctx app =
  let abs = validate ctx app.type' in
  let arg = validate ctx app.arg in
  let param = validate_app_param ctx abs in
  if not (Typing2.isa ctx arg param) then
    TypeError.validate_app_arg app param arg  else
  Typing2.compute ctx abs arg

and validate_app_param ctx abs =
  validate_app_param_union ctx abs

and validate_app_param_union ctx union =
  let types = List.map (validate_app_param_inter ctx) union.union in
  Utils.reduce_list (Typing2.meet ctx) types

and validate_app_param_inter ctx inter =
  let types = List.map (validate_app_param_base ctx) inter.inter in
  Utils.reduce_list (Typing2.join ctx) types

and validate_app_param_base ctx type' =
  match type' with
  | Var var ->
    let bound = TypeContext.get_bind_type ctx var.bind in
    validate_app_param ctx bound
  | Abs abs ->
    abs.param.bound
  | _ ->
    invalid_arg "validate_app_param_base"

and validate_param ctx param =
  let bound = validate ctx param.bound in
  { bind = param.bind; bound }
