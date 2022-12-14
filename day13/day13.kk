module day10

import std/core
import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

type element
  con List(lst: list<element>)
  con Int(i: int)

fun show(e: element): div string
    match e
      List(lst) -> lst.show-list(show)
      Int(i) -> i.show

struct packets
  left: element
  right: element

fun show(p: packets): div string
  p.left.show ++ "\n" ++ p.right.show ++ "\n"

fun show(ps: list<packets>): div string
  ps.map(show).join("\n")

fun parse-element(): <div, parse> element {
    (fn () val i = pint() in Int(i)) ||
    (fn() {
      char('[')
      val elems = parse-element.sep-by(pchar(','))
      char(']')
      List(elems)
    })
}

fun parse-packet(): <div, parse> packets {
  val left = parse-element()
  char('\n')
  val right = parse-element()
  char('\n')
  Packets(left, right)
}

fun inputs(s: string): <exn, div> list<packets> {
  val packets = s.split("\n\n")
  packets.filter-map(fn (p)  {
    match p.split("\n") {
      [left, right] -> Just(Packets(parse(left.slice, parse-element).unwrap, parse(right.slice, parse-element).unwrap))
      [""] -> Nothing
      lst -> throw("invalid packets " ++ lst.show)
    }
  })
}

fun correct-order(left: element, right: element): div order {
  fun ordered-zip(ll: list<element>, rr: list<element>): order {
    unsafe-no-div fn() {
      match ll {
        Nil -> match rr {
          Nil -> Eq
          Cons(_, _) -> Lt
        }
        Cons(l, ls) ->
          match rr {
            Nil -> Gt
            Cons(r, rs) ->
              match correct-order(l, r) {
                Eq -> ordered-zip(ls, rs)
                res -> res
              }
          }
      }
    }
  }

  match left {
    Int(li) -> match right {
      Int(ri) -> li.compare(ri)
      List(_) -> correct-order(List([Int(li)]), right)
    }
    List(l-lst) -> match right {
      Int(ri) -> correct-order(left, List([Int(ri)]))
      List(r-lst) -> ordered-zip(l-lst, r-lst)
    }
  }
}

fun count-correct-packets(ps: list<packets>): <console, div> int {
  ps.map-indexed(fn(i, p) (i + 1, p)).filter-map(fn((i, p)) {
    match correct-order(p.left, p.right)
      Gt -> Nothing
      _ -> Just(i)
  }).sum
}

fun sort-packets(ps: list<packets>): int {
  val div-pack0 = List([List([Int(2)])])
  val div-pack1 = List([List([Int(6)])])
  val is-div-pack = fn(p) {
    match p
      List([List([Int(6)])]) -> True
      List([List([Int(2)])]) -> True
      _ -> False
  }
  Cons(div-pack0, Cons(div-pack1, ps.flatmap(fn (p) [p.left, p.right])))
    .sort-by(fn(a, b) unsafe-total { correct-order(a, b) } )
    .map-indexed(fn(i, p) (i + 1, p))
    .filter-map(fn ((i, p)) 
      if p.is-div-pack
        then Just(i)
        else Nothing
    )
    .product
}

fun product(xs: list<int>): int {
  match xs {
    Nil -> 1
    Cons(x, xx) -> xx.foldl(x, (*))
  }
}

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  val packets = inputs(contents)
  packets.count-correct-packets.show.println
  packets.sort-packets.show.println
}
