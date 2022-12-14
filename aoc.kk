import std/num/int32
import std/text/parse

// Fail Fastly
fun join<a>(m: maybe<maybe<a>>): maybe<a>
  match m
    Just(Just(a)) -> Just(a)
    _ -> Nothing

fun unwrap<a>(m: maybe<a>): <exn> a
  match m
    Just(a) -> a
    Nothing -> throw("Expected Just value, got nothing")

fun unwrap<a>(p: parse-error<a>): <exn> a
  match p
    ParseOk(a, _) -> a
    ParseError(msg, _) -> throw(msg)

// Lists
fun scanl(xs: list<a>, seed: b, f: (b, a) -> e b): e list<b> {
  scanl-acc(xs, seed, Nil, f)
}
fun scanl-acc(xs: list<a>, seed: b, acc: list<b>, f: (b, a) -> e b): e list<b> {
  match xs {
    Nil -> Cons(seed, acc).reverse
    Cons(x, xx) -> xx.scanl-acc(f(seed, x), Cons(seed, acc), f)
  }
}

fun chunk<a>(xs: list<a>, n: int): list<list<a>> {
  val (hd, tail) = xs.split(n);
  match tail
    Nil -> Cons(hd, Nil)
    _ -> Cons(hd, unsafe-decreasing(tail).chunk(n))
}

alias difflist<a> = (list<a>) -> list<a>

fun sort-by(unsort: list<a>, compare: (a, a) -> order): list<a> {
  // Haskell? Ha ha, never heard of it!
  fun sequences(lst: list<a>, cmp_: (a, a) -> order): div list<list<a>> {
    fun descending(x: a, xs: list<a>, yss: list<a>, cmp: (a, a) -> order): div list<list<a>> {
      match yss
        Nil -> Cons(Cons(x, xs), Nil.sequences(cmp))
        Cons(y, ys) ->
          match x.cmp(y)
            Gt -> descending(y, Cons(x,xs), ys, cmp)
            _ -> Cons(Cons(x,xs), Cons(y, ys).sequences(cmp))
    }

    fun ascending(x: a, xs: difflist<a>, yss: list<a>, cmp: (a, a) -> order): div list<list<a>> {
      match yss
        Cons(y, ys) -> {
          match x.cmp(y) {
            Gt -> val a = xs([x]) in Cons(a, Cons(y, ys).sequences(cmp))
            _ -> ascending(y, (fn(bs) xs(Cons(x,bs))), ys, cmp)
          }
        }
        Nil -> Cons(xs([x]), Nil.sequences(cmp))
    }

    match lst
      Cons(a, Cons(b, xs)) ->
        match a.cmp_(b)
          Gt -> descending(b, [a], xs, cmp_)
          _ -> ascending(b, fn (l) Cons(a,l), xs, cmp_)
      xs -> [xs]
  }

  fun merge(xss: list<a>, yss: list<a>, cmp: (a, a) -> order): list<a> {
    match xss {
      Cons(x, xs) ->
        match yss {
          Cons(y, ys) ->
            match x.cmp(y) {
              Gt -> Cons(y, merge(xss, ys, cmp))
              _ -> Cons(x, merge(xs, yss, cmp))
            }
          Nil -> xss
        }
      Nil -> yss
    }
  }

  fun mergePairs(xs, cmp) {
    match xs
      Cons(a, Cons(b, tl)) -> Cons(merge(a, b, cmp), tl.mergePairs(cmp))
      lst -> lst
  }

  fun mergeAll(xs, cmp) {
    match xs
      [x] -> x
      lst -> lst.mergePairs(cmp).mergeAll(cmp)
  }

  // If this diverges I'll end my koka career
  // I'll hang up my fbip forever
  unsafe-no-div {
    unsort.sequences(compare).mergeAll(compare)
  }
}

fun dedup-by(lst: list<a>, compare: (a,a) -> order): list<a> {
  fun go(x: a, yss: list<a>, cmp: (a, a) -> order): list<a> {
    match yss {
      Cons(y, ys) ->
        match x.cmp(y)
          Eq -> go(x, ys, cmp)
          _ -> Cons(x, y.go(ys, cmp))
      Nil -> [x]
    }
  }

  match lst.sort-by(compare) {
    Nil -> Nil
    Cons(x, xs) -> x.go(xs, compare)
  }
}

// Parsing
fun lexeme(s: string): parse string
  whitespace0()
  val str = pstring(s)
  whitespace0()
  str

fun sep-by(p: parser<e, a>, sep: parser<e, b>): <parse|e> list<a> {
  (fn() {
    val head = p();
    val rest = many(fn() val x = sep() in p());
    Cons(head, rest)
  }) || (fn() Nil)
}

fun pchar(c: char): parser<<>, char>
  fn() char(c)

// Custom Datastructures
// Bit set for 'a'-'z'
struct lower-char-set
  bits: int32

fun lower-char-set(): lower-char-set
  Lower-char-set(zero)

fun bit(c: char): int32
  1.i32.shl(c.int - 'a'.int)
  
fun contains(set: lower-char-set, c: char): bool 
  set.bits.and(c.bit) != zero

fun insert(set: lower-char-set, c: char): lower-char-set
  Lower-char-set(set.bits.or(c.bit))
  
fun remove(set: lower-char-set, c: char): lower-char-set
  Lower-char-set(set.bits.xor(c.bit))

// Queue
struct queue<a>
  init: list<a>
  tail: list<a>

fun new(): queue<a> {
  Queue([], [])  
}

fun pop-front(q: queue<a>): maybe<(a, queue<a>)> {
  match q.init {
    Cons(x, xs) -> Just((x, q(init = xs)))
    Nil -> match q.tail.reverse {
      Cons(x, xs) -> Just((x, q(init = xs, tail = [])))
      Nil -> Nothing
    }
  }
}

fun is-empty(q: queue<a>): bool {
  match q.init {
    Cons(_, _) -> False
    Nil -> match q.tail {
      Cons(_, _) -> False
      Nil -> True
    }
  }
}
fun cons(q: queue<a>, x: a): queue<a> {
  q(init = Cons(x, q.init))
}
fun snoc(q: queue<a>, x: a): queue<a> {
  q(tail = Cons(x, q.tail))
}
fun prepend(q: queue<a>, xs: list<a>): queue<a> {
 q(init = xs ++ q.init)
}
fun append(q: queue<a>, xs: list<a>): queue<a> {
  q(tail = xs ++ q.tail)
}

// Grid
struct grid<h, a>
  width: int
  height: int
  data: ref<h, vector<a>>

fun show-grid(g: grid<h, a>, mk-str: a -> string): <div, read<h> | e> string {
  (!g.data).list.map(mk-str).chunk(g.width).map(fn(l) l.join).join("\n")
}


fun [](^grid: grid<h, a>, point: point): <read<h>, div, exn> a
  if point.outside(grid) then throw(point.show ++ " outside grid with dimensions " ++ (grid.width, grid.height).show)
  (!grid.data)[point.y * grid.width + point.x]

fun [](^grid: grid<h, a>, point: point, value: a): <read<h>, write<h>, exn, div|e> ()
  if point.outside(grid) then throw(point.show ++ " outside grid with dimensions " ++ (grid.width, grid.height).show)
  modify(grid.data, fn(data) {
    val indx = point.y * grid.width + point.x;
    data[indx] := value
  })

struct point
  x: int
  y: int

fun show(p: point): string
  "{ x: " ++ p.x.show ++ ", y: " ++ p.y.show ++ " }"

fun (-)(a: point, b: point): point {
  Point(a.x - b.x, a.y - b.y)
}

fun outside(point: point, grid: grid<h, a>): bool {
  point.x < 0 || point.x >= grid.width || point.y < 0 || point.y >= grid.height
}

// Pairs
fun show(pair: (int, int)): string {
  "(" ++ pair.fst.show ++ ", " ++ pair.snd.show ++ ")"
}

fun (+)(a: (int, int), b: (int, int)): (int, int) {
  (a.fst + b.fst, a.snd + b.snd)
}

fun (==)(a: (int, int), b: (int, int)): bool
  a.fst == b.fst && a.snd == b.snd
