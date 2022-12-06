import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

struct crates
  crates: ref<global, vector<list<char>>>

fun show(c: crates): string {
  var out := ""
  c.crates.foreach-indexed(fn (i, stack) {
    out := out ++ ((i + 1).show ++ ": " ++ stack.reverse.show-list(show) ++ "\n")
  })
  out
}

fun reverse-move-to(src: list<a>, n: int, dst: list<a>): (list<a>, list<a>) {
  val (mv, remain) = src.split(n);
  (remain, mv ++ dst)
}

fun move-to(src: list<a>, n:int, dst: list<a>): exn (list<a>, list<a>) {
  if n == 0
    then (src, dst)
    else {
      match src
        Nil -> throw("Something went wrong")
        Cons(x, xs) -> move-to(xs, n - 1, Cons(x, dst))
    } 
}

fun exec(machine: crates, inss: list<instruction>, move-fn = move-to): exn crates {
  inss.foreach(fn(ins) {
    machine.crates.modify(fn(v: local-var<h, vector<list<char>>>): <local<h>, exn> () {
      val (new-src, new-dst) = move-fn(v[ins.src], ins.amount, v[ins.dst])
      v[ins.src] := new-src
      v[ins.dst] := new-dst
    })
  })
  machine
}

fun parse-crates(): parse list<list<maybe<char>>> {
  fun parse-a-crate(): parse maybe<char>
    choose([
      fn() {
        pstring("   ");
        Nothing
      },
      fn() {
        char('[');
        val letter = alpha();
        char(']');
        Just(letter)
      }
    ])
  
  fun parse-line(): parse list<maybe<char>>
    parse-a-crate.sep-by(pchar(' '))
  
  parse-line.sep-by(pchar('\n'))
}

fun construct-crates(parse: list<list<maybe<char>>>): <exn, alloc<global>> crates {
    val crate-count = parse[0].unwrap.length 
    val crates = vector-init(crate-count, fn(i) {
      parse.filter-map(fn(l) l[i].join)
    })
    Crates(ref(crates))
}

struct instruction
  amount: int
  src: int 
  dst: int

fun parse-ins(): parse instruction {
  lexeme("move")
  val amount = pint()
  lexeme("from")
  val src = pint()
  lexeme("to")
  val dst = pint()
  whitespace0()
  Instruction(amount, src - 1, dst - 1)
}

fun show(ins: instruction): string {
  "move " ++ ins.amount.show ++ " from " ++ ins.src.show ++ " to " ++ ins.dst.show
}

fun show(inss: list<instruction>): string {
  inss.map(show).join("\n")
}

fun parse-instructions(): parse list<instruction>
  many(parse-ins)

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)

  // Initial split of input into crates and instructions
  val split = contents.split("\n\n")
  val crates-str = split[0].unwrap
  val ins-str = split[1].unwrap
  
  // Parse each segment of text
  val raw-crates = parse(crates-str.slice, parse-crates).unwrap
  val inss = parse(ins-str.slice, parse-instructions).unwrap

  val crates = construct-crates(raw-crates)
  println(crates.show) 
  println(crates.exec(inss).show)
  println(crates.exec(inss, reverse-move-to).show)
}
