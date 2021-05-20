# llvm-hs-tutor
A Haskell version of the llvm-tutor project using llvm-hs

## Overview

Working directly with LLVM in C++ is tedious, unsafe, and highly error-prone.
It is possible to write code that behaves like an out-of-source LLVM pass
directly in Haskell. There is little to no performance difference in practice,
because we are using the LLVM C API via `llvm-hs`.

The goal of this project is to showcase that LLVM can in fact be easy and fun to
work with. This is demonstrated through a collection of self-contained testable
passes which are implemented using idiomatic Haskell.

## HelloWorld: Your First Haskell Pass

The HelloWorld pass in `app/HelloWorld.hs` demonstrates the basics of working
with LLVM from Haskell.

### Development Environment

If you are using your system-wide installed version of LLVM, you should not
need to do any special setup. You can build the example passes by saying

```
stack build
```

If you have built LLVM from source, then you will need to tell stack where to
look for the LLVM tools (such as the `llvm-config` utility), and shared
libraries. The simplest way to do this is to prefix your stack commands like
so:

```
LD_LIBRARY_PATH=$(realpath ../llvm-12.0.0-root/lib) PATH=$(realpath ../llvm-12.0.0-root/bin):$PATH stack build
```

Before you can test the HelloWorld pass, you need to prepare and input file:

```
clang -S -emit-llvm inputs/input_for_hello.c -o input_for_hello.ll
```

Run `HelloWorld` with stack like so:

```
stack exec -- helloworld input_for_hello.ll
Hello from: Name "foo"
  number of arguments: 1
Hello from: Name "bar"
  number of arguments: 2
Hello from: Name "fez"
  number of arguments: 3
Hello from: Name "main"
  number of arguments: 2
```
