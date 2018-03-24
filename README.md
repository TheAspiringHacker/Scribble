# Scribble
Scribble is still a work in progress, but it will be a block-based functional
(ML-style) programming language.

## Building
The editor is implemented in vanilla JavaScript. Navigate to `editor/index.html`
in your browser to test the editor.

The language is implemented in OCaml and requires Dune to build.

Run `jbuilder runtest to run the tests`.

## Deploying
The repository is hosted on GitHub for development, but on GitLab for deployment
because of GitLab CI, which supports GitLab Pages. To push to GitLab, run

    git push gitlab

## Licensing
This software is licensed under the GNU GPLv3. The files under the `lang`
subdirectory are additionally licensed under the MIT (Expat) license.
