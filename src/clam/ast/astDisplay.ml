open Ast

type node =
  | Prog      of Ast.program
  | Def       of Ast.def
  | Type      of Ast.type'
  | Expr      of Ast.expr
  | Param     of Ast.param
  | FieldType of Ast.field_type
  | FieldExpr of Ast.field_expr
  | Stmt      of Ast.stmt

type attr =
  | ANode   of node
  | AList   of node list
  | AOption of node option
  | AString of string

let node_name node =
  match node with
  | Prog _ -> "program"
  | Def def -> "def." ^ (match def with
    | DefType _ -> "type"
    | DefExpr _ -> "expr")
  | Type type' -> "type." ^ (match snd type' with
    | TypeIdent       _ -> "name"
    | TypeAbsExpr     _ -> "abs_expr"
    | TypeAbsExprType _ -> "abs_expr_type"
    | TypeProduct     _ -> "product"
    | TypeInter       _ -> "inter"
    | TypeUnion       _ -> "union"
    | TypeAbs         _ -> "abs"
    | TypeApp         _ -> "app")
  | Expr expr -> "expr." ^ (match snd expr with
    | ExprUnit      -> "unit"
    | ExprTrue      -> "true"
    | ExprFalse     -> "false"
    | ExprInt     _ -> "int"
    | ExprChar    _ -> "char"
    | ExprString  _ -> "string"
    | ExprBind    _ -> "bind"
    | ExprTuple   _ -> "tuple"
    | ExprProduct _ -> "product"
    | ExprElem    _ -> "elem"
    | ExprAttr    _ -> "attr"
    | ExprPreop   _ -> "preop"
    | ExprBinop   _ -> "binop"
    | ExprAscr    _ -> "ascr"
    | ExprIf      _ -> "if"
    | ExprAbs     _ -> "abs"
    | ExprApp     _ -> "app"
    | ExprTypeAbs _ -> "type_abs"
    | ExprTypeApp _ -> "type_app"
    | ExprStmt    _ -> "stmt")
  | FieldType _ -> "field_type"
  | FieldExpr _ -> "field_expr"
  | Param _ -> "param"
  | Stmt stmt -> "stmt." ^ (match stmt with
    | StmtVar  _ -> "var"
    | StmtExpr _ -> "expr")

let node_attrs node =
  match node with
  | Prog { defs } -> [("defs", AList (List.map (fun def -> Def def) defs))]
  | Def def -> (match def with
    | Ast.DefType type' ->
      [("name", AString type'.name); ("type", ANode (Type type'.type'))]
    | Ast.DefExpr { name; type'; expr; _ } ->
      [("name", AString name); ("type", AOption (Option.map (fun type' -> Type type') type')); ("expr", ANode (Expr expr))])
  | Type type' -> (match snd type' with
    | TypeIdent name ->
      [("name", AString name)]
    | TypeAbsExpr (params, return) ->
      [("params", AList (List.map (fun param -> Type param) params)); ("expr", ANode (Type return))]
    | TypeAbsExprType (params, return) ->
      [("params", AList (List.map (fun param -> Param param) params)); ("expr", ANode (Type return))]
    | TypeProduct fields ->
      [("fields", AList (List.map (fun field -> FieldType field) fields))]
    | TypeInter (left, right) ->
      [("left", ANode (Type left)); ("right", ANode (Type right))]
    | TypeUnion (left, right) ->
      [("left", ANode (Type left)); ("right", ANode (Type right))]
    | TypeAbs (params, return) ->
      [("params", AList (List.map (fun param -> Param param) params)); ("type", ANode (Type return))]
    | TypeApp (type', args) ->
      [("type", ANode (Type type')); ("args", AList (List.map (fun arg -> Type arg) args))])
  | Expr expr -> (match snd expr with
    | ExprUnit -> []
    | ExprTrue -> []
    | ExprFalse -> []
    | ExprInt value ->
      [("value", AString value)]
    | ExprChar value ->
      [("value", AString value)]
    | ExprString value ->
      [("value", AString value)]
    | ExprBind name ->
      [("name", AString name)]
    | ExprTuple exprs ->
      [("exprs", AList (List.map (fun expr -> Expr expr) exprs))]
    | ExprProduct fields ->
      [("fields", AList (List.map (fun field -> FieldExpr field) fields))]
    | ExprElem (expr, index) ->
      [("expr", ANode (Expr expr)); ("index", AString index)]
    | ExprAttr (expr, attr) ->
      [("expr", ANode (Expr expr)); ("attr", AString attr)]
    | ExprPreop (op, expr) ->
      [("op", AString op); ("expr", ANode (Expr expr))]
    | ExprBinop (left, op, right) ->
      [("left", ANode (Expr left)); ("op", AString op); ("right", ANode (Expr right))]
    | ExprAscr (expr, type') ->
      [("expr", ANode (Expr expr)); ("type", ANode (Type type'))]
    | ExprIf (cond, then', else') ->
      [("cond", ANode (Expr cond)); ("then", ANode (Expr then')); ("else", ANode (Expr else'))]
    | ExprAbs (params, expr) ->
      [("params", AList (List.map (fun param -> Param param) params)); ("expr", ANode (Expr expr))]
    | ExprApp (expr, args) ->
      [("expr", ANode (Expr expr)); ("args", AList (List.map (fun arg -> Expr arg) args))]
    | ExprTypeAbs (params, expr) ->
      [("params", AList (List.map (fun param -> Param param) params)); ("expr", ANode (Expr expr))]
    | ExprTypeApp (expr, args) ->
      [("expr", ANode (Expr expr)); ("args", AList (List.map (fun arg -> Type arg) args))]
    | ExprStmt (stmt, expr) ->
      [("stmt", ANode (Stmt stmt)); ("expr", ANode (Expr expr))])
  | FieldType { type'; _ } ->
    [("type", ANode (Type type'))]
  | FieldExpr { expr; _ } ->
    [("expr", ANode (Expr expr))]
  | Param { name; type'; _ } ->
    [("name", AString name); ("type", AOption (Option.map (fun type' -> Type type') type'))]
  | Stmt stmt -> (match stmt with
    | StmtVar (name, type', expr) ->
      [("name", AString name); ("type", AOption (Option.map (fun type' -> Type type') type')); ("expr", ANode (Expr expr))]
    | StmtExpr expr ->
      [("expr", ANode (Expr expr))])

let rec indent tab =
  if tab == 0
    then ""
    else "  " ^ (indent (tab - 1))

let rec display_node tab node =
  let attrs = node_attrs node in
  (node_name node) ^ (if List.length attrs != 0
    then " {\n" ^ (String.concat "" (List.map (fun (name, attr) -> (indent (tab + 1)) ^ name ^ ": " ^ display_attr (tab + 1) attr) attrs)) ^ (indent tab) ^ "}"
    else "")
    ^ "\n"

and display_attr tab attr =
  match attr with
  | ANode node     -> display_node tab node
  | AList nodes    -> "[\n" ^ (String.concat "" (List.map (fun node -> (indent (tab + 1)) ^ display_node (tab + 1) node) nodes)) ^ (indent tab) ^ "]\n"
  | AOption option -> (match option with
    | Some node -> "some " ^ display_node tab node
    | None      -> "none\n")
  | AString string -> "\"" ^ string ^ "\"\n"

let display_program (prog: Ast.program) = "\n" ^ (display_node 0 (Prog prog))
