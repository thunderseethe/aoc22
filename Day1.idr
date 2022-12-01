module Day1

import Control.App
import Control.App.Console
import Control.App.FileIO

hello : (Console es, FIleIO es) => App es ()
hello = do
  file_path <- getLine
  readFile file_path

main : IO ()
main = run hello
