module day10

import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

// I leave this here as a a testament to my failure. 
// May someone stronger than I carry the torch.
//pub co type stream2<a>
//  con Next2(head: a, tail: delayed<<>, stream2<a>>)
//  
//fun repeat(x: a): stream2<a>
//  Next2(x, delay(fn() repeat(x)))
//
//fun drop(s: stream2<a>, count: int): stream2<a> {
//  match count
//    0 -> s
//    n -> s.tail.force.drop(n - 1)
//}
//
//fun zipWith(a: stream2<a>, op: (a, b) -> c, b: stream2<b>): stream2<c>
//  Next2(
//    head = a.head.op(b.head),
//    tail = delay(fn() a.tail.force.zipWith(op, b.tail.force))
//  )
//
//fun unfold(init: a, next: (a) -> a) : stream2<a>
//  Next2(head = init, tail = delay(fn() init.next.unfold(next)))
//
//fun ints(): stream2<int>
//  unfold(0, inc)
//
//fun enumerate(s: stream2<a>): stream2<(int, a)>
//  ints().zipWith(fn(a, b) (a, b), s)
//
//fun stream-of(ins: vector<maybe<int>>): <console, exn> stream2<int>
//  fun tick(step:int): <console, exn> stream<int> {
//    step.show.println
//    match ins[step % ins.length] {
//      Nothing -> Next2(head = 0, tail = delay(fn() tick(step + 1)))
//      Just(add) -> {
//        val s = tick(step + 1);
//        Next2(
//          head = 0, 
//          tail = s(tail = delay(fn() s.tail.force.zipWith((+), add.repeat)))
//        )
//      }
//    }
//  }
//  tick(0)
 
// This is wrong
//fun ticks(inss: vector<maybe<int>>, steps: int): exn list<int> {
//  val x = 1
//  with handler {
//    ctl tick(ins) {
//      match ins
//        // noop
//        Nothing -> Cons(x, resume(()))
//        // addx
//        Just(amount) -> {
//          val l = match resume(()) {
//            Cons(a, Cons(b, tl)) -> Cons(a, Cons(b, tl.map(fn(x) x + amount)))
//            lst -> lst
//          }
//          Cons(x, l)
//        }
//    }
//    return (_) Nil
//  }
//
//  for(0, steps) fn(step) {
//    tick(inss[step % inss.length]);
//  }
//}

effect wip
  ctl tick(ins: maybe<int>, x: int): int

fun ticks(inss: list<maybe<int>>, cycles: int): div list<(int, int)> {
  // Cycles are 1-indexed
  var cycle := 1
  with handler {
    ctl tick(ins: maybe<int>, x: int) {
      if cycle > cycles then
        return Nil
      match ins {
        // noop
        Nothing -> {
          val hd = (cycle, x)
          cycle := cycle.inc;
          Cons(hd, resume(x))
        }
        // addx
        Just(amount) -> {
          val (a, b) = ((cycle, x), (cycle.inc, x))
          cycle := cycle.inc.inc;
          Cons(a, Cons(b, resume(x + amount)))
        }
      }
    }
    return (_) Nil
  }
  var x := 1;
  // where's cycle() when you need it
  while(fn() True) fn() {
    inss.foreach fn(ins) {
      x := tick(ins, x);
    }
  }
}

fun parse-input(): parse list<maybe<int>>
  many(fn()
    choose([
      fn() { lexeme("noop"); Nothing },
      fn() { 
        lexeme("addx"); 
        val inc = pint();
        whitespace0();
        Just(inc)
      }
    ])
  )

fun sum-specific-signals(signals: list<(int, int)>): console int {
  signals.filter(fn ((cycle, _))
    cycle == 20 || cycle == 60 || cycle == 100 || cycle == 140 || cycle == 180 || cycle == 220
  ).map(fn ((cycle, x)) cycle * x).sum
}

fun format-crt(signals: list<(int, int)>): console string {
  signals.chunk(40)
    .map(fn(row) {
      row.show-list(show).println 
      row.map(fn((cycle,  x)) { 
        val c = cycle.dec % 40;
        if (c - x).abs <= 1
          then '#'
          else '.'
      }).string
    }).join("\n")
}

fun show(state: (int, int)): string
  "(" ++ state.fst.show ++ ", " ++ state.snd.show ++ ")"

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  val inss = parse(contents.slice, parse-input).unwrap
  inss.length.show.println
  val signals = ticks(inss, 240);
  //signals.show-list(show).println
  signals.sum-specific-signals.show.println
  signals.format-crt.println
}
