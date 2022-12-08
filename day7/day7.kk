module day7

import std/os/env
import std/os/file
import std/os/path
import std/text/parse
import aoc

type parse-fileset
  con PDir(name: string)
  con PFile(size: int, name: string)

fun show(fs: parse-fileset): string {
  match fs
    PDir(name) -> "dir " ++ name
    PFile(size, name) -> size.show ++ " " ++ name
}

type cmd
  con Cd(dir: string)
  con Ls(files: list<parse-fileset>)

fun show(c: cmd): string {
  match c 
    Cd(dir) -> "$ cd " ++ dir
    Ls(fs) -> "$ ls\n" ++ fs.map(show).join("\n")
}

struct file
  name: string
  size: int

fun show(f: file): string {
  f.name ++ " " ++ f.size.show
}

struct dir
  name: string
  size: int
  files: list<file>
  subdirs: list<dir>

fun show(d: dir): div string {
  fun indent-str(indent: int): string {
    ' '.replicate(indent).string
  }
  fun go(indent: int, d: dir): div string {
    indent.indent-str ++ "dir " ++ d.name ++ "(" ++ d.size.show ++ ")" ++ "\n"
      ++ d.files.map(show).map(fn(s) (indent + 2).indent-str ++ s ++ "\n").join("")
      ++ d.subdirs.map(fn(d) go(indent + 2, d)).join("")
      ++ "\n"
  }
  go(0, d)
}

fun filtered(dir, pred: (dir) -> bool): div list<dir> {
  val tail = dir.subdirs.flatmap(fn(d) d.filtered(pred))
  if pred(dir)
    then Cons(dir, tail)
    else tail
}

fun at-most(dir: dir, threshold: int): div list<dir> {
  dir.filtered(fn(d) d.size <= threshold)
}

fun at-least(dir: dir, threshold: int): div list<dir> {
  dir.filtered(fn(d) d.size >= threshold)
}

fun sizes(dirs: list<dir>): list<int> {
  dirs.map(fn(d) d.size)
}

type dir-zipper
  Root
  WithinDir(name: string, files: list<file>, dirs: list<dir>, hole: dir-zipper)

fun as-dir(zipper: dir-zipper)
  match zipper
    Root -> throw("Cannot use Root as dir")
    WithinDir(name, files, dirs, Root) -> 
      Dir(
        name, 
        files.map(fn(f) f.size).sum + dirs.sizes.sum,
        files,
        dirs
      )
    the-big-z ->
      the-big-z.pop-dir.as-dir

fun pop-dir(zipper: dir-zipper)
  match zipper
    Root -> throw("Cannot pop dir from root")
    WithinDir(name, files, dirs, zipper) -> {
      val dir = Dir(
        name, 
        files.map(fn(f) f.size).sum + dirs.map(fn(d) d.size).sum,
        files,
        dirs
      )
      zipper.add-dir(dir)
    }

fun add-dir(zipper: dir-zipper, dir: dir)
  match zipper
    Root -> throw("Cannot add dir to root")
    WithinDir(name, file, dirs, zipper) ->
      WithinDir(name, file, Cons(dir, dirs), zipper)

fun add-file(zipper: dir-zipper, file: file)
  match zipper
    Root -> throw("Cannot add file to root")
    WithinDir(name, files, dirs, zipper) -> 
      WithinDir(name, Cons(file, files), dirs, zipper)

fun calculate-sizes(cmds: list<cmd>): <div, exn> dir
  var zipper := Root
  cmds.foreach fn(cmd) {
    match cmd
      Cd("..") -> {
        zipper := zipper.pop-dir()
      }
      Cd(name) -> {
        zipper := WithinDir(name, [], [], zipper)
      }
      Ls(fileset) -> {
        fileset.foreach fn(entry) {
          match entry  
            PDir(_) -> {}
            PFile(size, name) -> {
              zipper := zipper.add-file(File(name, size))
            }
        }
      }
  }
  zipper.as-dir
 
fun parse-name(): parse string
  chars-are("dir/file name", fn(c) !c.is-white).string

fun parse-cd(): parse cmd {
  lexeme("$ cd")
  val name = parse-name()
  whitespace0()
  Cd(name)
}

fun parse-dir(): parse parse-fileset {
  lexeme("dir")
  val name = parse-name()
  whitespace0()
  PDir(name)
}

fun parse-file(): parse parse-fileset {
  val size = pint()
  whitespace()
  val name = parse-name()
  whitespace0()
  PFile(size, name)
}

fun parse-ls(): parse cmd {
  lexeme("$ ls")
  val fileset = many(fn() choose([
    parse-dir,
    parse-file
  ]))

  Ls(fileset)
}

fun parse-input(): parse list<cmd>
  many(fn() choose([ 
    parse-cd,
    parse-ls,
  ]))

fun main() {
  with ctl throw-exn(ex)
    println(ex.message)
  val file-path = get-args()[0].unwrap
  val contents = read-text-file(file-path.path)
  val terminal = parse(contents.slice, parse-input).unwrap
  val dir = terminal.calculate-sizes

  // Part 1
  dir.at-most(100000).sizes.sum.show.println

  // Part 2
  val update-space = 30000000
  val unussed-space = 70000000 - dir.size
  val needed-space = update-space - unussed-space
  dir.at-least(needed-space).sizes.minimum.show.println
}
