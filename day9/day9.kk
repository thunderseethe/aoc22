module day9

import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

fun (+)(a: (int, int), b: (int, int)): (int, int) {
  (a.fst + b.fst, a.snd + b.snd)
}

fun (-)(a: (int, int), b: (int, int)): (int, int) {
  (a.fst - b.fst, a.snd - b.snd)
}

fun (*)(scalar: int, v: (int, int)): (int, int) {
  (scalar * v.fst, scalar * v.snd)
}

fun (*)(v: (int, int), scalar: int): (int, int) {
  scalar * v
}

fun magn(a: (int, int), b: (int, int)): int
  val dx = (b.fst - a.fst)
  val dy = (b.snd - a.snd)
  (dx * dx) + (dy * dy)

fun dot(a: (int, int), b: (int, int)): int {
  a.fst * b.fst + a.snd * b.snd
}

fun unit(v: (int, int)) {
  (v.fst / v.fst.abs, v.snd / v.snd.abs)
}


fun cmp(a: (int, int), b: (int, int)): order {
  match a.fst.compare(b.fst)
    Eq -> a.snd.compare(b.snd)
    ord -> ord
}

fun show(v: (int, int)): string
  "<" ++ v.fst.show ++ ", " ++ v.snd.show ++ ">"

type dir
  con U
  con L
  con R
  con D

fun velocity(dir: dir): (int, int)
  match dir
    U -> (0, 1)
    L -> (-1, 0)
    R -> (1, 0)
    D -> (0, -1)

fun parse-dir(): parse dir
  choose([
    (fn() val u = char('U') in U),
    (fn() val r = char('R') in R),
    (fn() val l = char('L') in L),
    (fn() val d = char('D') in D),
  ])

struct ins
  dir: dir
  steps: int

fun parse-ins(): parse ins
  val dir = parse-dir()
  whitespace()
  val steps = pint()
  whitespace0()
  Ins(dir, steps) 

fun parse-input(): parse list<ins>
  many(parse-ins)

struct rope {
  head: (int, int) = (0, 0);
  tail: (int, int) = (0, 0)
}

// 1, 1
// -1, -1 

fun snap(head: (int, int), tail: (int, int), dir: dir): (int, int) {
  val vel = head - tail
  if dot(vel, vel) <= 2
    then tail
    else tail + vel.unit
}

fun pull(r: rope, dir: dir): rope {
  val head = r.head + dir.velocity
  r(head = head, tail = head.snap(r.tail, dir))
}

effect tails<a>
  fun yield(elem: a): ()

struct big-rope {
  knots: list<(int, int)>
}

fun pull(br: big-rope, dir: dir): tails<(int, int)> big-rope {
  fun go(last: (int, int), tail: list<(int, int)>) {
    match tail {
      Cons(knot, tl) -> Cons(last, go(last.snap(knot, dir), tl))
      Nil -> { yield(last); Cons(last, Nil) }
    }
  }
  val knots = match br.knots {
    Cons(old-hd, tail) -> {
      val head = old-hd + dir.velocity
      go(head, tail) 
    }
    Nil -> Nil
  }
  br(knots = knots)
}
  
fun count-locations(inss: list<ins>): console int {
  var r := Rope()
  // always include starting location
  var lst := [(0, 0)]
  inss.foreach fn(ins) {
    for(0, ins.steps - 1) fn (_) {
      r := r.pull(ins.dir)
      lst := Cons(r.tail, lst)
    }
  }
  val sorted = lst.sort-by(cmp)
  val dedup = sorted.dedup-by(cmp)
  sorted.length.show.println
  dedup.length
}

fun count-big-locations(inss: list<ins>): console int {
  var lst := []
  with fun yield(tail: (int, int))
    lst := Cons(tail, lst)
  
  var br := Big-rope(knots = (0,0).replicate(10))
  inss.foreach fn(ins) {
    for(0, ins.steps - 1) fn (_) {
      br := br.pull(ins.dir)
    }
  }
  lst.dedup-by(cmp).length
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  val inss = parse(contents.slice, parse-input).unwrap

  inss.count-locations.show.println
  inss.count-big-locations.show.println
}
