(lang dune 3.21)
(name ml-paint)
(generate_opam_files true)
(source
 (github lessp/mlpaint))
(authors "Tom Ekander -- lessp.dev")
(maintainers "Tom Ekander -- lessp.dev")

(license MIT)

(documentation https://url/to/documentation)

(package
 (name ml-paint)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml tsdl ocaml-lsp-server wall tgls)
 (tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
