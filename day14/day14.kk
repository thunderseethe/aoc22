module day10

import std/core
import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

struct boundingbox
  topleft: point
  bottomright: point

fun outside(p: point, bb: boundingbox): bool {
  p.x < bb.topleft.x || p.x > bb.bottomright.x || p.y < bb.topleft.y || p.y > bb.bottomright.y
}

fun show(bb:boundingbox): string
  bb.topleft.show ++ " <> " ++ bb.bottomright.show

fun union(a: boundingbox, b: boundingbox): boundingbox {
  Boundingbox(
    Point(min(a.topleft.x, b.topleft.x), min(a.topleft.y, b.topleft.y)),
    Point(max(a.bottomright.x, b.bottomright.x), max(a.bottomright.y, b.bottomright.y))
  )
}

fun unions(bs: list<boundingbox>): exn boundingbox {
  bs.foldl1(union)
}

fun xmax(b: boundingbox): int {
  b.bottomright.x
}
fun xmin(b: boundingbox): int {
  b.topleft.x
}
fun ymax(b: boundingbox): int {
  b.bottomright.y
}
fun ymin(b: boundingbox): int {
  b.topleft.y
}

type delta
  Dx(dx: int)
  Dy(dy: int)

fun show(d: delta): string {
  match d
    Dx(dx) -> "Dx(" ++ dx.show ++ ")"
    Dy(dy) -> "Dy(" ++ dy.show ++ ")"
}

fun delta(p: point): maybe<delta> {
  if p.y == 0  then Just(Dx(p.x))
  elif p.x == 0 then Just(Dy(p.y))
  else Nothing
}

fun normalize(p: point, b:boundingbox): point {
  p - b.topleft
}

fun (+)(p: point, d: delta): point {
  match d {
    Dx(dx) -> p(x = p.x + dx)
    Dy(dy) -> p(y = p.y + dy)
  }
}

struct rock
  start: point
  shape: list<delta> 

fun inflection-points(rock: rock): list<point>
  rock.shape.scanl(rock.start) fn(point, delta) {
    point + delta
  }

fun points(rock: rock): list<point>
  rock.shape.flatmap(fn(d) {
    match d {
      Dx(x) -> (if x < 0 then Dx(-1) else Dx(1)).replicate(x.abs)
      Dy(y) -> (if y < 0 then Dy(-1) else Dy(1)).replicate(y.abs)
    }
  }).scanl(rock.start, (+))
  
fun show(rock: rock): string
  rock.start.show ++ ": " ++ rock.shape.show-list(show)

fun prettyprint(rock: rock): string
  fun show-point(p: point): string
    p.x.show ++ "," ++ p.y.show

  rock.inflection-points.map(show-point).join(" -> ")

fun dimensions(r: rock): boundingbox {
  var xmin := 4000000000
  var xmax := 0
  var ymin := 4000000000
  var ymax := 0
  r.points.foreach fn(point) {
    xmax := max(point.x, xmax)
    xmin := min(point.x, xmin)

    ymax := max(point.y, ymax)
    ymin := min(point.y, ymin)
  }

  Boundingbox(Point(xmin, ymin), Point(xmax, ymax))
}

fun parse-rock(): <exn, console, parse> rock
  val start = { 
    val x = pint()
    char(',')
    val y = pint()
    Point(x, y)
  }
  val (_, deltas) = many({
    pstring(" -> ")
    val x = pint()
    char(',')
    val y = pint()
    Point(x, y)
  }).foldl((start, [])) fn((last, deltas), point) {
    val d = (point - last).delta.unwrap
    (point, Cons(d, deltas))
  }
  Rock(start, deltas.reverse) 
 
fun parse-input()
  parse-rock.sep-by({char('\n')})

type mat
  R // Rock
  A // Air
  S // Sand

fun is-air(m: mat): bool
  match m
    A -> True
    _ -> False

fun make-grid(rs: list<rock>) {
  val bounding = rs.map(dimensions).unions
  val width = bounding.xmax() + 1000
  val height = bounding.ymax().inc.inc
  (width, height).show.println
  var v := vector(width * height, A)
  rs.foreach fn(rock) {
    rock.points.foreach fn(p) {
      v[p.y * width + p.x] := R
    }
  }
  (bounding, Grid(width, height, ref(v)))
}

fun fill-sand-naive(rs: list<rock>) {
  val (bb, grid) = make-grid(rs)
  bb.show.println
  var continue := True
  var sand-count := 0
  var p := Point(500, 0)
  while (fn () p.y < bb.ymax && grid[p].is-air) {
    if p.outside(grid) || grid[p + Dy(1)].is-air then p := p + Dy(1)
    elif grid[p + Dy(1) + Dx(-1)].is-air then p := p + Dy(1) + Dx(-1)
    elif grid[p + Dy(1) + Dx(1)].is-air then p := p + Dy(1) + Dx(1)
    else {
      sand-count := sand-count.inc
      grid[p] := S
      p := Point(500, 0)
    }
  }
  grid.show-bb(bb, fn(mat) {
    match mat
      A -> "."
      R -> "#"
      S -> "o"
  }).println
  sand-count
}

fun fill-sand-with-floor(rs)
  val (bb, grid) = make-grid(rs)
  var continue := True
  var sand-count := 0
  var p := Point(500, 0)
  while (fn () grid[p].is-air) {
    if p.y == bb.ymax + 1 then {
      sand-count := sand-count.inc
      grid[p] := S
      p := Point(500, 0)
    }
    elif p.outside(grid) || grid[p + Dy(1)].is-air then p := p + Dy(1)
    elif grid[p + Dy(1) + Dx(-1)].is-air then p := p + Dy(1) + Dx(-1)
    elif grid[p + Dy(1) + Dx(1)].is-air then p := p + Dy(1) + Dx(1)
    else {
      sand-count := sand-count.inc
      grid[p] := S
      p := Point(500, 0)
    }
  }
  grid.show-bb(bb, fn(mat) {
    match mat
      A -> "."
      R -> "#"
      S -> "o"
  }).println
  sand-count

fun show-bb(grid: grid<h, a>, bb: boundingbox, mk-str: a -> string): <pure, read<h>|e> string {
  var s := ""
  for(bb.ymin(), bb.ymax()) fn(y) {
    for(bb.xmin(), bb.xmax()) fn(x) {
      val pstr = grid[Point(x, y)]
      s := s ++ mk-str(pstr)
    }
    s := s ++ "\n"
  }
  s
}


fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  val rocks = parse(contents.slice, parse-input).unwrap
  val rocks-with-floor = {
    val bb = rocks.map(dimensions).unions
    val floor = Rock(
      start = Point(bb.xmin(), bb.ymax() + 2),
      shape = [Dx(1000)]
    )
    Cons(floor, rocks)
  }
  rocks.fill-sand-with-floor.show.println
}
