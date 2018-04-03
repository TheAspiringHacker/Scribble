# Scribble
Scribble is still a work in progress, but it will be a block-based functional
(ML-style) programming language.

## Installing dependencies
Dependencies:
- OPAM
- Dune (Jbuilder)
- Js_of_ocaml

If this is your first time using OPAM, run `opam init`. Also switch to the
latest version of the compiler with `opam switch 4.06.1`.

Install Dune and Js_of_ocaml through OPAM.

## Building
The editor is implemented in vanilla JavaScript. Navigate to `editor/index.html`
in your browser to test the editor.

The language is implemented in OCaml and requires Dune (former Jbuilder) to
build. In the `lang` subdirectory, run `jbuilder runtest` to run the tests and
`jbuilder build src/jsoo/compiler.bc.js` to build the compiler.

## Deploying
The repository is hosted on GitHub for development, but on GitLab for deployment
because of GitLab CI, which supports GitLab Pages. To push to GitLab, run

    git push gitlab

## Licensing
This software is licensed under the GNU GPLv3. The files under the `lang`
subdirectory are additionally licensed under the MIT (Expat) license.
