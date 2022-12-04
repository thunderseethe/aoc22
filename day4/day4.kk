import std/os/env
import std/os/file
import std/os/path
import std/text/parse

struct sections
  start: int
  end: int

fun parse-sections(): parse sections {
  val start = pint();
  char('-')
  val end = pint();
  Sections(start, end)
}

fun parse-input(): parse list<(sections, sections)> {
  many({
    val first = parse-sections();
    char(',')
    val second = parse-sections();
    whitespace0();
    (first, second)
  })
}

fun contains(a: sections, b: sections): bool {
  a.start <= b.start && a.end >= b.end
}

fun overlaps(a: sections, b: sections): bool {
  a.start >= b.start && a.start <= b.end
  || a.end >= b.start && a.end <= b.end
}

fun within((fst-sections, snd-sections): (sections, sections)): bool {
  fst-sections.contains(snd-sections) || snd-sections.contains(fst-sections)
}

fun overlaps((fst-sections, snd-sections): (sections, sections)): bool {
  fst-sections.overlaps(snd-sections) || snd-sections.overlaps(fst-sections)
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = 
    match (get-args()[0])
      Just(file-path) -> file-path
      Nothing -> throw-exn(Exception("I'm a failure", ExnError))
  val contents = read-text-file(file-path.path)
  val sections = 
    match parse-eof(contents.slice, parse-input)
      ParseOk(sections, _) -> sections
      ParseError(msg, _) -> throw(msg)
  val full-overlap-count = sections.filter(within).length
  val partial-overlap-count = sections.filter(overlaps).length
  println("Full Overlap Count: " ++ full-overlap-count.show)
  println("Partial Overlap Count: " ++ partial-overlap-count.show)
}
