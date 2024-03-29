open Node

let rec compare (left: type') (right: type') =
  compare_union left right

and compare_union left right =
  List.equal compare_inter left.union right.union

and compare_inter left right =
  List.equal compare_base left.inter right.inter

and compare_base left right =
  match left, right with
  | Top    , Top    -> true
  | Bot    , Bot    -> true
  | Unit   , Unit   -> true
  | Bool   , Bool   -> true
  | Int    , Int    -> true
  | String , String -> true
  | Var left_var, Var right_var ->
    left_var.bind == right_var.bind
  | Tuple left_tuple, Tuple right_tuple ->
    Util.compare_lists compare left_tuple.elems right_tuple.elems
  | Record left_record, Record right_record ->
    Util.compare_maps compare_attr left_record.attrs right_record.attrs
  | Lam left_lam, Lam right_lam ->
    compare left_lam.param right_lam.param
    && compare left_lam.ret right_lam.ret
  | Univ left_univ, Univ right_univ ->
    compare_param left_univ.param right_univ.param
    && let right_ret = Rename.rename right_univ.ret right_univ.param.bind left_univ.param.bind in
    compare left_univ.ret right_ret
  | Abs left_abs, Abs right_abs ->
    compare_param left_abs.param right_abs.param
    && let right_body = Rename.rename right_abs.body right_abs.param.bind left_abs.param.bind in
    compare left_abs.body right_body
  | App left_app, App right_app ->
    compare left_app.abs right_app.abs
    && compare left_app.arg right_app.arg
  | _ -> false

and compare_param left_param right_param =
  left_param.bind.name == right_param.bind.name
  && compare left_param.lower right_param.lower
  && compare left_param.upper right_param.upper

and compare_attr left_attr right_attr =
  compare left_attr.type' right_attr.type'
