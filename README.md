# What is this ?

This is  Clam ! A small statically typed functional programming language with many classic but interesting type features.

# Example

A Clam program is a sequence of type and term definitions, declared respectively with the keywords `type` and `def`. The order of these definitions is unimportant.

When a program is executed, the `main` term definition is evaluated.

Printing is done through the (impure) `print` function, which can be chained with other terms using a semicolon.

```
def fibonacci: (Int) -> Int = (n) ->
    if n == 0 | n == 1 then
        n
    else
        fibonacci(n - 2) + fibonacci(n - 1)

def main =
    print(fibonacci(2));
    print(fibonacci(5));
    unit
```

More examples of Clam code can be found in the `tests` directory.

# How to build

You can build this project on Linux using Dune.

In a terminal, enter `dune build` to build the project or `dune exec main example.clam` to run the interpreter with the code file `example.clam` as an input.

# Features

Most of the interesting things about Clam are in its type system, which while not very original, incorporates many ideas notably of System $F^ω_{<:}$.

## Product types

Product types and values in Clam are defined with curly braces, and can either be tuples or records. Tuple fields are indexed by their order and record fields are indexed by their labels. Fields are accessed using the dot operator `.` and the empty product `{}` is considered to be a record.

```
type Tuple = {Int, Int}
type Record = {x: Int, y: Int}

def tuple: Tuple = {0, 1}
def record: Record = {x = 2, y = 3}

def zero = tuple.0
def two = record.x
```

## Structural subtyping

Clam features structural subtyping, meaning that two structurally equivalent types are considered to be equal. Records are considered extensible by subtyping while tuples are not.

```
type 2D = {x: Int, y: Int}
type 3D = {x: Int, y: Int, z: Int}

def 3d: 3D = {x = 0, y = 0, z = 0}
def 2d: 2D = 3d
```

## Unit type

Clam has a default unit type named `Unit`, whose only value is `unit`.

```
def u: Unit = unit
```

## Top type

Clam has a top type named `Top`, which is a supertype of all proper types.

```
def a: Top = 0
def b: Top = "Hello world !"
```

## Bottom type

Clam has a bottom type named `Bot`, which is a subtype of all types.

```
def foo = (bot: Bot) ->
    var a: Unit   = bot;
    var b: String = bot;
    unit
```

## Universal types

Clam features universal types, which allow to abstract over a term using types.

```
type Iter = [T] -> (Int, T, (T) -> T) -> T

def iter: Iter = [T] -> (n, v, f) ->
    if n == 0 then
        v
    else
        iter[T](n - 1, f(v), f)

def eight = iter(3, 1, (i) -> i * 2)
```

## Type constructors

Clam features type constructors, which allow to abstract over a type using other types. Type parameters have a bound, which is `Top` by default.

```
type Pair = [T] => {T, T}

def pair: Pair[Int] = {0, 0}
```

## Currying

Clam features currying, which allows the partial application of type and term abstractions with multiple parameters. Currying is enabled by Clam's lambda-calculus-like core, where abstractions and applications are decomposed into their unary form.

```
def add = (a: Int, b: Int) -> a + b

def step = add(1)
def three = step(2)
```

## Higher-kinded types

Clam features higher-kinded types, which allow type constructors to abstract over other type constructors.

```
type Monad = [M: [T] => Top, A] => {
    return: (A) -> M[A],
    bind: [B] -> (M[A], (A) -> M[B]) -> M[B]
}

type State = [S, T] => (S) -> {T, S}

def state_monad: [S, A] -> Monad[State[S], A] = [S, A] -> {
    return = (a: A, s: S) -> {a, s},
    bind = [B] -> (m: State[S, A], f: (A) -> State[S, B], s: S) ->
        var bs = m(s);
        f(bs.0, bs.1)
}
```

## Union and intersection types

Clam features union and intersection types, with integrated distribution, joins and meets.

```
type Union = {foo: Int} | {foo: String}
type Inter = {bar: Int} & {baz: String}

def union: Union = {foo = 1}
def inter: Inter = {bar = 2, baz = "World"}

def foo: Int | String = union.foo

def distributivity = [A, B, C] -> (developed: (A & B) | (A & C)) ->
    var factorized: A & (B | C) = developed;
    unit
```

## Bidirectional type inference

Clam features bidirectional type inference, which allows to eliminate many type annotations when they are not needed.

```
type Make = [T] -> (T) -> {T, T}

def make: Make = [T] -> (p) -> {p, p}

def main =
    var pair = make[Int](0);
    unit
```

## Recursive types

Clam does not feature recursive types yet, which is quite limiting.

# Roadmap

Here are a few features I would like to eventually work on in the future:
1. Finish higher-order types, double-check features and add more testing
2. Better (monadic) error handling and reporting
4. Add recursive types
5. Add negation types
6. Add pattern matching using types
7. Add function totality checking

# Notes

Clam is simply a pet project of mine, it is not intended to be a full-blown programming language. I created it during my master's thesis evaluation to learn OCaml, practice functional programming and apply some of the knowledge I had gained on types and type theory.

As said in the roadmap, some features are not complete yet, although the examples do work.
