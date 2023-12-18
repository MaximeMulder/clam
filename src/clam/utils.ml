module NameKey = struct
  type t = string
  let compare = String.compare
end

module NameMap = Map.Make(NameKey)

module NameSet = Set.Make(NameKey)

let flip f x y = f y x
let uncurry f (x, y) = f x y

let extract key map =
  let value = NameMap.find key map in
  let map = NameMap.remove key map in
  (value, map)

let compare_lists compare list other =
  if List.compare_lengths list other != 0 then false else
  let pairs = List.combine list other in
  let compare_pair = fun (a, b) -> compare a b in
  List.for_all compare_pair pairs

let compare_maps compare map other =
  let list = List.of_seq (NameMap.to_seq map) in
  let other = List.of_seq (NameMap.to_seq other) in
  if List.compare_lengths list other != 0 then false else
  let pairs = List.combine list other in
  List.for_all (fun (entry, other_entry) ->
    (fst entry) = (fst other_entry) && compare (snd entry) (snd other_entry)
  ) pairs

let rec reduce_list f xs =
  match xs with
  | [x] -> x
  | x :: xs -> f x (reduce_list f xs)
  | _ -> invalid_arg "Utils.reduce_list"

let option_join x y f =
  match (x, y) with
  | (Some x, Some y) -> Some (f x y)
  | (Some x, None) -> Some x
  | (None, Some y) -> Some y
  | _ -> None

let option_meet x y f =
  match (x, y) with
  | (Some x, Some y) -> Some (f x y)
  | _ -> None

let rec list_option_meet xs f =
  match xs with
  | [x] ->
    x
  | x :: xs ->
    option_meet x (list_option_meet xs f) f
  | _ ->
    invalid_arg "list_option_meet"

let rec list_option_join xs f =
  match xs with
  | [x] ->
    x
  | x :: xs ->
    option_join x (list_option_join xs f) f
  | _ ->
    invalid_arg "list_option_join"

let rec product_lists acc f l1 l2 =
  match (l1, l2) with
  | ([], _) | (_, []) ->
    acc
  | (h1 :: t1, h2 :: t2) ->
    let acc = (f h1 h2) :: acc in
    let acc = product_lists acc f t1 l2 in
    product_lists acc f [h1] t2

let product_lists f l1 l2 =
  product_lists [] f l1 l2

let rec collapse n xs ys zs f =
  match xs with
  | [] -> (
    match ys with
    | [] -> n :: zs
    | y :: ys -> collapse y ys [] (n :: zs) f)
  | x :: xs -> (
    match f n x with
    | Some n -> collapse n (xs @ ys @ zs) [] [] f
    | None -> collapse n xs (x :: ys) zs f)

let collapse f xs =
  match xs with
  | x :: xs -> collapse x xs [] [] f
  | _ -> invalid_arg "collapse"
