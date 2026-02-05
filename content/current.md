---
title: Current
show_meta: no
---

Here's what I'm currently working on:

## [Stamail](https://git.chappelle.dev/stamail/log.html)

A [suckless](https://suckless.org) static site generator for mailing list
archives

Current state:

- Parses maildir into s-expression using notmuch
- Creates abstract syntax tree from s-expression
- Creates message lists and thread trees from s-expression
- HTML rendered parses lists and trees into a static webpage

Current bugs:

- ~~Generating empty erraneous message nodes~~
- Threading HTML is _ugly_
- Navigation of site, and aesthetic, isn't where it should be

## [Gromacs-LS](https://github.com/vanegasj/gromacs-ls-2025.4)

A fork of [Gromacs](https://www.gromacs.org), a moluecular dynamics simulation
engine, with support for local stress and elasticity simulation. The project is
authored and maintained by Juan Vanegas, a Biophysics professor and researcher
at OSU.

- Focusing on:
  - Porting Gromacs-LS from v2016.3 of Gromacs to v2025.4
  - Adivsing team members on:
    - Implementation of automatic-differentiation into the
      [MDStress](https://vanegaslab.org/software) library.
    - Performance profiling of MDStress library, including:
      - Actual CPU time and memory space
      - Interpretation of compiler generated assembly

## [verso_2](https://git.chappelle.dev/verso2/log.html)

A minimal, unix-centric, and easy static site generator. It's what this site is
built on

Currently:

- Working out the kinks as I create posts, add content, and expand the
  capabilities
- Exploring ways to integrate my [stagit](https://git.chappelle.dev) instance
  into the site, as well as other cool bonuses

## Computer Architecture

Currently taking High Performance Computer Architectures (CS 570 at OSU) as well
as exploring creating a Verilog design of my own out-of-order RISC-V cpu

- Focusing on:
  - Out-of-order pipelines
  - Branch prediction optimizations

## Privacy and Security

Currently taking a class on Privacy and Surveillance (CS 577 at OSU)

- Focusing on:
  - [Privacy in Context](https://www.sup.org/books/law/privacy-context) by Helen
    Nissebaum
  - How changing contexts define how we feel about technologies, whether the
    technology is explicitly for surveillance or not
