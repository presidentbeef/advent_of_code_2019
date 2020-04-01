# Advent of Code 2019 - In Pony

Herein lies the dusty remains of late-night, unpolished, unpretty solutions
to the first 9 days of [Advent of Code 2019](https://adventofcode.com/2019),
written in [Pony](https://www.ponylang.io/).

It was my intention to complete all 25 days, then go back and polish up the solutions,
document them, et cetera. But I no longer believe that will ever happen.

So, in their natural, raw, uncut state they will remain, probably forever.
Perhaps they will retain some pedagogical value, but probably not.

## Environment

These programs were originally compiled with `ponyc` 0.33.1 on x86_64 Linux.

I suggest using [`ponyup`](https://github.com/ponylang/ponyup), it's pretty slick.

## Structure

Each day of Advent of Code has two parts.

For simplicity, each day is in its own directory and then the parts are in
directories `a` and `b` in files named `a.pony` and `b.pony`.

Note that Pony doesn't care what its files are named. It goes by the name of the directory.

Each solution is self-contained.

The file `input.text` contains the input I received from Advent of Code.
Each person gets different input, so you may wish to change it if you are
going through Advent of Code yourself.

You can assume the output is correct for the input provided here.
It may require massaging.

## Compiling / Running

Change directories to the directory containing the solution you care about.

Run `ponyc`.

The output will be an executable named `a` or `b`.

Run `./a` or `./b`.

In most cases, this will spit out the solution based on the `input.text`.

There may be one or two that require special handling.
You'll have to read the code to find out.

## License

MIT
