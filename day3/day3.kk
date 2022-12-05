import std/os/env
import std/os/file
import std/os/path
import std/num/int64
import aoc

effect double-ended-iterate {
  ctl yield(front: char, back: char): bool
  ctl odd-one-out(c: char): ()
}

fun iterate(s: string): <div, double-ended-iterate, exn> () {
  var start := 0
  var end := s.slice.count - 1
  val vsack = s.vector
  while (fn() start < end) {
    yield(vsack[start], vsack[end]);
    start := start + 1;
    end := end - 1
  }
  if start == end
    then odd-one-out(vsack[start])
    else ()
}

fun bit(c: char): int64 {
  if c.is-upper
    then 1.i64.shl(c.int - 38)
    else 1.i64.shl(c.int - 96)
}

fun component(bit: int64): int {
  for-while(1, 52) fn(i) {
    if bit.and(1.i64.shl(i)).bool
      then Just(i)
      else Nothing
  }.default(0)
}

fun find-error-component(rucksack: string): <div, exn, console> int {
  var fst := zero;
  var snd := zero;
  handle (fn() rucksack.iterate)
    fun yield(front: char, back: char) {
      fst := fst.or(front.bit);
      snd := snd.or(back.bit);
      False
    }
    fun odd-one-out(c: char) {
      throw-exn(Exception("Ruck sack had odd length", ExnError))
    }
    return (_) {
      fst.and(snd).component
    }
}

fun construct-rucksack(s: string): int64 {
  var rucksack := zero
  s.slice.foreach fn(c) {
    rucksack := rucksack.or(c.bit)
  }
  rucksack
}

fun sum-group-badge(rucksacks: list<int64>): <div, exn> int {
  rucksacks
    .chunk(3)
    .map(fn (group) group.foldr1(and).component)
    .sum
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = 
    match (get-args()[0])
      Just(file-path) -> file-path
      Nothing -> throw-exn(Exception("I'm a failure", ExnError))
  val contents = read-text-file(file-path.path)
  val total-error-comp = contents.lines.map(find-error-component).sum
  val group-totals = contents.lines.map(construct-rucksack).sum-group-badge
  println("Total Error Components: " ++ total-error-comp.show)
  println("Group Components: " ++ group-totals.show)
}
