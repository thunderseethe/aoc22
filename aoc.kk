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
fun chunk<a>(xs: list<a>, n: int): <div> list<list<a>> {
  val (hd, tail) = xs.split(n);
  match tail
    Nil -> Cons(hd, Nil)
    _ -> Cons(hd, tail.chunk(n))
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
