import std/os/env
import std/os/file
import std/os/path
import std/core


fun split-up(input: string): list<list<int>> {
  input
    .split("\n\n")
    .map fn(lst) {
      lst.split("\n").map fn(s) {
        s.parse-int-default(0)
      }
    }
}

fun max-calories(calories: list<list<int>>): int {
  calories.map(sum).maximum
}

effect iterate {
  ctl yield(i: int): ()
}

struct max3 {
  a : int = 0
  b : int = 0
  c : int = 0
}

fun top3-calories(calories: list<list<int>>): <console> int {
  var max := Max3()
  with handler {
    fun yield(i) {
      if i > max.a && i <= max.b then max := max(a = i)
      else if i > max.b && i <= max.c then max := max(a = max.b, b = i)
      else if i > max.c  then max := max(a = max.b, b = max.c, c = i)
      else ()
    }
    return (x) { max.a + max.b + max.c }
  } 
  calories.map(sum).foreach(yield)
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = 
    match (get-args()[0])
      Just(file-path) -> file-path
      Nothing -> throw-exn(Exception("I'm a failure", ExnError))
  val contents = read-text-file(file-path.path)
  val calories = split-up(contents)
  println("Max calories: " ++ show(max-calories(calories)))
  println("Top 3 calories: " ++ show(top3-calories(calories)))
}
