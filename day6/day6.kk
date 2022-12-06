import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

effect sliding-window<a>
  fun view(slice: sslice): maybe<a>

fun window(s: string, n: int): <sliding-window<a>> maybe<a>{
  val len = s.slice.count
  var slice := s.first(n)
  for-while(0, len - 1 - n) fn(_) {
    val res = view(slice);
    slice := slice.advance(1);
    res
  }
}

fun is-marker(ss: sslice): bool {
  var charset := lower-char-set()
  ss.foreach-while(fn(c) {
    if charset.contains(c)
      then Just(False)
      else { charset := charset.insert(c); Nothing }
  }).default(True)
}

fun find-marker(s: string, window-size: int): <exn,console> int {
  var i := 0
  with handler {
    fun view(ss: sslice) {
      val q = i;
      i := inc(i);
      if ss.is-marker()
        then Just(q + window-size)
        else Nothing
    }
    return (mi)
      match mi
        Just(n) -> n
        Nothing -> throw("Failed to find marker")
  }
  s.window(window-size)
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  find-marker(contents, 4).show.println
  find-marker(contents, 14).show.println
}
