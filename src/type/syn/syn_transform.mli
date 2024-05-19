(**
  This module provides generic helpers for syntactic transformations on types.
*)

(**
  [syn_map f type']

  Map over [type'] by applying [f] to each of its components.

  Usually, [syn_map] should be called in a recursive function that handles the
  special cases and calls [syn_map] with itself, possibly partially applied, as an
  argument to handle the other cases where no special treatement is needed.
*)
val syn_map : (Node.type' -> Node.type') -> Node.type' -> Node.type'

(**
  [syn_fold f1 f2 acc type']

  Fold over [type'] by mapping its components with [f1] and folding the results
  with [f2] and [acc].

  Usually, [syn_fold] should be called in a recursive function that handles the
  special cases and calls [syn_fold] with itself, possibly partially applied, as an
  argument to handle the other cases where no special treatement is needed.
*)
val syn_fold : (Node.type' -> 'a) -> ('a -> 'a -> 'a) -> 'a -> Node.type' -> 'a
