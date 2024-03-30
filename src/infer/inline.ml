open Polar
open State

type entry = {
  bind: Abt.bind_type;
  neg: Type.type';
  pos: Type.type';
}

let rec inline entry pol (type': Type.type') =
  match type' with
  | Dnf dnf ->
    inline_union entry pol dnf
  | Cnf _ ->
    raise (invalid_arg "TODO")

and inline_union entry pol union =
  let* types = list_map (inline_inter entry pol) union in
  list_fold join (Type.bot) types

and inline_inter entry pol inter =
  let* types = list_map (inline_base entry pol) inter in
  list_fold meet (Type.top) types

and inline_base entry pol type' =
  match type' with
  | Top | Bot | Unit | Bool | Int | String ->
    return (Type.base type')
  | Var var when var.bind == entry.bind -> (
    match pol with
    | Neg ->
      return entry.neg
    | Pos ->
      return entry.pos)
  | Var var ->
    return (Type.var var.bind)
  | Tuple tuple ->
    let* elems = list_map (inline entry pol) tuple.elems in
    return (Type.tuple elems)
  | Record record ->
    let* attrs = map_map (inline_attr entry pol) record.attrs in
    return (Type.record attrs)
  | Lam lam ->
    let* param = inline entry (inv pol) lam.param in
    let* ret = inline entry pol lam.ret in
    return (Type.lam param ret)
  | Univ univ ->
    let* param = inline_param entry (inv pol) univ.param in
    let* ret = with_type univ.param.bind univ.param.lower univ.param.upper (inline entry pol univ.ret) in
    return (Type.univ param ret)
  | _ ->
    return (Type.base type')

and inline_attr entry pol attr =
  let* type' = inline entry pol attr.type' in
  return { attr with type' }

and inline_param entry _pol param =
  let* lower = inline entry Pos param.lower in
  let* upper = inline entry Neg param.upper in
  return { param with lower; upper }

let inline bind neg pos pol type' =
  inline { bind; neg; pos } pol type'
