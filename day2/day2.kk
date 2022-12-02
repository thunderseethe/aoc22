import std/os/env
import std/os/file
import std/os/path
import std/text/parse

type play
  Rock
  Paper
  Scissors

type result
  Win
  Draw
  Lose

fun score(opp: play, me: play): int {
  match (me, opp) {
    (Rock, Paper) -> 0
    (Rock, Rock) -> 3
    (Rock, Scissors) -> 6
    (Paper, Scissors) -> 0
    (Paper, Paper) -> 3
    (Paper, Rock) -> 6
    (Scissors, Rock) -> 0
    (Scissors, Scissors) -> 3
    (Scissors, Paper) -> 6
    _ -> 0
  }
}
 
fun int(p: play): int {
  match p
    Rock -> 0
    Paper -> 1
    Scissors -> 2
}

fun play(i: int): maybe<play> {
  match i
    0 -> Just(Rock)
    1 -> Just(Paper)
    2 -> Just(Scissors)
    _ -> Nothing
}

fun score(p: play): int {
  p.int + 1
}

fun score-game((opp, me): (play, play)): int {
  me.score + score(opp, me)
}

fun score-result((opp, res): (play, result)): int {
  match res 
    Lose -> (opp.int + 2) % 3 + 1 + 0
    Draw -> opp.score + 3
    Win -> (opp.int + 1) % 3 + 1 + 6
}

fun pfirst-play(): parse play
  satisfy-fail("expected first play") fn(slice) {
    match slice.next
      Just(('A', remain)) -> Just((Rock, remain))
      Just(('B', remain)) -> Just((Paper, remain))
      Just(('C', remain)) -> Just((Scissors, remain))
      _ -> Nothing
  }

fun psecond-play(): parse (play, result)
  satisfy-fail("expected second play") fn(slice) {
    match slice.next
      Just(('X', remain)) -> Just(((Rock, Lose), remain))
      Just(('Y', remain)) -> Just(((Paper, Draw), remain))
      Just(('Z', remain)) -> Just(((Scissors, Win), remain))
      _ -> Nothing
  }

fun games-parser(): parse list<(play, (play, result))> {
  many(fn() {
    val fst = pfirst-play();
    whitespace();
    val snd = psecond-play();
    whitespace0();
    (fst, snd)
  })
}

fun select-game(p: (play, (play, result))): (play, play)
  (p.fst, p.snd.fst)

fun select-result(p: (play, (play, result))): (play, result)
  (p.fst, p.snd.snd)
  

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = 
    match (get-args()[0])
      Just(file-path) -> file-path
      Nothing -> throw-exn(Exception("I'm a failure", ExnError))
  val contents = read-text-file(file-path.path)
  val games = 
    match parse-eof(contents.slice, games-parser)
      ParseOk(games, _) -> games
      ParseError(err, _) -> throw-exn(Exception("ParseError: " ++ err, ExnError))
  val total-score = games.map(select-game).map(score-game).sum
  val rigged-score = games.map(select-result).map(score-result).sum
  println("Game Score: " ++ total-score.show)
  println("Result Score: " ++ rigged-score.show)
}
