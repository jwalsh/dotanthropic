#!/usr/bin/env python3
import sys
import subprocess
import os

def create_archive_org(outfile, files):
   with open(outfile, 'w') as f:
       f.write("#+TITLE: Code Archive\n")
       f.write("#+PROPERTY: header-args :tangle yes :mkdirp yes\n\n")
       
       for filepath in files:
           name = os.path.basename(filepath)
           ext = os.path.splitext(filepath)[1][1:] or "text"
           
           f.write(f"* {name}\n")
           f.write(f"#+BEGIN_SRC {ext} :tangle {filepath}\n")
           with open(filepath) as src:
               f.write(src.read())
           f.write("\n#+END_SRC\n\n")

def extract_files(archive_org):
   cmd = [
       "emacs", "-Q", "--batch",
       "--eval", "(require 'org)",
       "--eval", f"(org-babel-tangle-file \"{archive_org}\")"
   ]
   subprocess.run(cmd, check=True)

if __name__ == "__main__":
   if len(sys.argv) < 3:
       print("Usage: script.py archive.org file1 file2 ...")
       sys.exit(1)
       
   archive = sys.argv[1]
   files = sys.argv[2:]
   
   create_archive_org(archive, files)
   extract_files(archive)
