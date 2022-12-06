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

// Custom Datastructures
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
