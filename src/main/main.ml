type config = {
  show_ast    : Util.writer option;
  show_kinds  : Util.writer option;
  show_types  : Util.writer option;
  show_values : Util.writer option;
  print_out   : Util.writer;
  print_err   : Util.writer;
  debug_infer : bool;
}

let parse code config =
  let ast = Parser.parse code in
  (match config.show_ast with
  | Some show_ast -> show_ast(Ast.display_program ast);
  | None -> ());
  ast

let desugar ast =
  Sugar.desugar ast Prim.binds

let type_check abt config =
  let kinds, types = Infer.check abt Prim.types in
  (match config.show_kinds with
  | Some show_kinds ->
    List.iter (fun (name, kind) ->
      show_kinds(name ^ " :: " ^ Type.Kind.display kind)
    ) kinds
  | None -> ());
  match config.show_types with
  | Some show_types ->
    List.iter (fun (def, type') ->
      show_types((def: Abt.bind_expr).name ^ ": " ^ Type.display type')
    ) types
  | None -> ()

let eval abt config =
  let main = (match List.find_opt (fun (def: Abt.def_expr) -> def.bind.name = "main") abt.Abt.exprs with
  | Some main -> main
  | None -> Error.handle_main () config.print_err
  ) in
  Eval.eval main abt.exprs Prim.values config.print_out

let run code config =
  if config.debug_infer then
    Infer.debug_flag := true;
  try
    let ast = parse code config in
    let abt = desugar ast in
    type_check abt config;
    eval abt config
  with
  | Parser.Error error ->
    Error.handle_parser error config.print_err
  | Sugar.Error  error ->
    Error.handle_sugar  error config.print_err
  | Type.Error   error ->
    Error.handle_type   error config.print_err
  | Infer.Error  error ->
    Error.handle_infer  error config.print_err
  | Eval.Error   error ->
    Error.handle_eval   error config.print_err
