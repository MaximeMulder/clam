module type MONAD = sig
  type 'a t
  val return: 'a -> 'a t
  val bind: 'a t -> ('a -> 'b t) -> 'b t
end

module Monad (M: MONAD) = struct
  include M

  let (let*) = bind

  let rec map_list f xs =
    match xs with
    | [] -> return []
    | x :: xs ->
      let* x = f x in
      let* xs = map_list f xs in
      return (x :: xs)

  let map_option f x =
    match x with
    | None -> return None
    | Some x ->
      let* x = f x in
      return (Some x)
end

module type STATE = sig
  type s
end

module StateMonad (S: STATE) = struct
  open S

  type 'a t = s -> ('a * s)

  let return a s = (a, s)

  let bind m f =
    fun s ->
      let (a, s1) = m s in
      let (b, s2) = f a s1 in
      (b, s2)
end

module type READER = sig
  type r
end

module ReaderMonad (R: READER) = struct
  open R

  type 'a t = r -> 'a

  let return a _ = a

  let bind r f =
    fun c -> f (r c) c
end
