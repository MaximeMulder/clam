open Clam
open Vars

let test name left right expect (_: unit) =
  let result = Typing.join left right in
  let result = TypingCompare.compare result expect in
  Alcotest.(check bool) name true result

let name left right expect =
  let left   = TypingDisplay.display left   in
  let right  = TypingDisplay.display right  in
  let expect = TypingDisplay.display expect in
  "join `" ^ left ^ "` `" ^ right ^ "` `" ^ expect ^ "`"

let case left right expect =
  let name = name left right expect in
  let test = test name left right expect in
  Alcotest.test_case name `Quick test

let tests = [
  (* top *)
  case top top top;
  case top a top;
  case a top top;

  (* bottom *)
  case bot bot bot;
  case bot a a;
  case a bot a;

  (* primitives *)
  case unit unit unit;
  case bool bool bool;
  case int int int;
  case char char char;
  case string string string;

  (* variables *)
  case a a a;
  case a b (union a b);
  case a ea a;
  case ea a a;
  case ea fa (union ea fa);

  (* unions *)
  case a (union b c) (union a (union b c));
  case (union a b) c (union a (union b c));

  (* tuples *)
  case (tuple []) (tuple []) (tuple []);
  case (tuple [top]) (tuple [a]) (tuple [top]);
  case (tuple [a]) (tuple [top]) (tuple [top]);
  case (tuple [a]) (tuple [b]) (union (tuple [a]) (tuple [b]));
  case (tuple [a]) (tuple [a; b]) (union (tuple [a]) (tuple [a; b]));
  case (tuple [a; b]) (tuple [a]) (union (tuple [a; b]) (tuple [a]));
  case (tuple [a; b]) (tuple [c; d]) (union (tuple [a; b]) (tuple [c; d]));

  (* records *)
  case (record []) (record []) (record []);
  case (record [("foo", a)]) (record []) (record []);
  case (record []) (record [("foo", a)]) (record []);
  case (record [("foo", top)]) (record [("foo", a)]) (record [("foo", top)]);
  case (record [("foo", a)]) (record [("foo", top)]) (record [("foo", top)]);
  case (record [("foo", a)]) (record [("foo", b)]) (union (record [("foo", a)]) (record [("foo", b)]));
  case (record [("foo", a)]) (record [("bar", b)]) (union (record [("foo", a)]) (record [("bar", b)]));

  (* expression to expression abstractions *)
  case (abs_expr a b) (abs_expr a b) (abs_expr a b);
  case (abs_expr top b) (abs_expr a b) (abs_expr a b);
  case (abs_expr a b) (abs_expr top b) (abs_expr a b);
  case (abs_expr a top) (abs_expr a b) (abs_expr a top);
  case (abs_expr a b) (abs_expr a top) (abs_expr a top);
  case (abs_expr a c) (abs_expr b c) (union (abs_expr a c) (abs_expr b c));
  case (abs_expr a b) (abs_expr a c) (union (abs_expr a b) (abs_expr a c));
  case (abs_expr a b) (abs_expr c d) (union (abs_expr a b) (abs_expr c d));
]