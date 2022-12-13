module day10

import std/core
import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

struct grid<h>
  width: int
  height: int
  data: ref<h, vector<int>>

fun [](^grid: grid<h>, ^point: (int, int)): <read<h>, exn> int 
  (!grid.data)[point.snd * grid.width + point.fst]

fun [](^grid: grid<h>, ^point: (int, int), value: int): <read<h>, write<h>, exn|e> ()
  modify(grid.data, fn(data){
    data[point.snd * grid.width + point.fst] := value
  })

fun outside(point: (int, int), grid: grid<h>): bool {
  point.fst < 0 || point.fst >= grid.width || point.snd < 0 || point.snd >= grid.height
}

fun make-grid(s: string): <alloc<h>, console> (grid<h>, (int, int), (int, int)) {
  var max-width := 0
  var width := 0
  var height := 0

  var end := (0, 0)
  var start := (0, 0)

  val grid = s.lines.flatmap(fn(line) {
    width := 0
    val vec = line.list.map(fn(chr) {
      match chr {
        // S is treated as a
        'S' -> { start := (width, height); width := width.inc; 0 }
        // E is treated as z
        'E' -> { end := (width, height); width := width.inc; 'z'.int - 'a'.int }
        c -> { width := width.inc; c.int - 'a'.int }
      }
    })
    height := height.inc;
    max-width := width.max(max-width)
    vec
  }).vector
  (Grid(max-width, height - 1, ref(grid)), end, start)
}

effect memoize<a, r>
  fun cached(point: a): maybe<r>
  fun memoize(point: a, value: r): r

// we don't have a like int.max-value (that I could find). So just pick one that's likely to beat any value we see
fun a-really-big-int() 4000000000

fun minimum(xs: list<int>): e maybe<int>
  match xs
    Nil -> Nothing
    Cons(x, xx) -> Just(xx.foldl(x, min))

// This is way too slow :/
//fun find-shortest-path(global-grid: grid<h>, start: (int, int), end: (int, int)): <console, div, exn, read<h>> int {
//  var table := vector(global-grid.width * global-grid.height, -1)
//  with handler {
//    fun cached(p: (int, int)) {
//      if p.outside(global-grid) then return Nothing
//      val memo = table[p.snd * global-grid.width + p.fst]
//      if memo < 0 then Nothing
//      else Just(memo)
//    }
//    fun memoize(p: (int, int), dist) {
//      table[p.snd * global-grid.width + p.fst] := dist;
//      dist
//    }
//  }
//
//
//  fun pathfinder(
//    ^grid: grid<h>, 
//    visit: list<(int, int)>,
//    source: (int, int), 
//    dest: (int,int)
//  ): <console, div, memoize<(int,int), int>, exn, read<h>> maybe<int> {
//    if source.outside(grid)
//      then return Nothing
//    if source == dest
//      then return Just(memoize(source, 0))
//    if visit.find(fn (seen) seen == source).is-just
//      then return Nothing
//    match cached(source) {
//      Just(dist) -> Just(dist)
//      Nothing -> {
//        val dist = [(1, 0), (-1, 0), (0, 1), (0, -1)].filter-map(fn (delta) {
//          if (source + delta).outside(grid) then Nothing
//          elif grid[source] - grid[source + delta] > 1 then Nothing
//          else pathfinder(grid, Cons(source, visit), source + delta, dest)
//        })
//
//        match dist.minimum {
//          Just(steps) -> Just(memoize(source, steps + 1))
//          Nothing -> Nothing
//        }
//      }
//    }
//  }
//
//  pathfinder(global-grid, Nil, end, start);
//  (table[end.snd * global-grid.width + end.fst])
//}

fun calc-dists(grid: grid<h>, origin: (int, int)): <div, exn, read<h>> vector<int> {
  var table: vector<int> := vector(grid.width * grid.height, -1)
  with handler {
    fun cached(p: (int, int)) {
      if p.outside(grid) then return Nothing
      val memo = table[p.snd * grid.width + p.fst]
      if memo < 0 then Nothing
      else Just(memo)
    }
    fun memoize(p: (int, int), dist) {
      table[p.snd * grid.width + p.fst] := dist;
      dist
    }
  }

  var queue := new().cons((origin, 0))
  while(fn () queue.is-empty.not) {
    match queue.pop-front {
      Nothing -> ()
      Just(((p, steps), queue')) -> {
        if p.outside(grid) then return ()
        match cached(p) {
          Just(_) -> queue := queue'
          Nothing -> {
            memoize(p, steps);
            val neighbors = [(-1, 0), (0, -1), (1, 0), (0, 1)].filter-map(fn(delta) {
              if (p + delta).outside(grid) then Nothing
              elif grid[p] - grid[p + delta] > 1 then Nothing
              else Just((p + delta, steps + 1))
            });
            queue := queue.append(neighbors)
          } 
        }
      }
    }
  }

  table
}

fun find-shortest-path(grid: grid<h>, start: (int, int), end: (int, int)): <div, exn, read<h>> int {
  val table = calc-dists(grid, end);
  table[start.snd * grid.width + start.fst]
}

fun find-shortest-short-path(grid: grid<h>, end: (int, int)): <div, exn, read<h>> int {
  val table = calc-dists(grid, end);
  (!grid.data).list.zip(table.list)
           .filter(fn((a, dist)) a == 0 && dist != -1)
           .map(fn (p) p.snd)
           .minimum(-1)
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  val (grid, end, start): (grid<global>, (int, int), (int, int)) = make-grid(contents)
  ("Grid Dimensions: " ++ (grid.width, grid.height).show).println
  val dist = find-shortest-path(grid, start, end)
  dist.show.println
  find-shortest-short-path(grid, end).show.println
}
