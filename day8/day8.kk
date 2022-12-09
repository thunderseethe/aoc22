module day8 

import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

effect forest
  ctl max-visible(x: int, y:int): int
  ctl is-visible(x: int, y: int, tree: int): bool

fun dig(): parse int {
  val d = digit()
  whitespace0()
  d.int - '0'.int
}

fun parse-grid(): parse vector<int> {
    many(dig).vector
}

fun row(grid: vector<int>, (width, height): (int, int), x: int): list<int> {
}

fun count-visible(width: int, height: int, grid: vector<int>): int {
  val indx = fn(x, y) { y * width + x }

  var visible: vector<bool> := ref(vector-init(grid.length, fn(i) {
    val (y, x) = i.divmod(width)
    // All edges start visible
    if (x == 0) || (y == 0) || (x == width - 1) || (y == height - 1)
      then True
      else False
  }))

  for(1, width - 2) fn (x) {
    for(1, height - 2) fn (y) {
    }
  }
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  val lines = contents.lines
  val (width, height) = 
    (lines[0].unwrap.slice.count, lines.length)
  val grid = parse(contents, parse-grid).unwrap
}
