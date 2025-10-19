(lang dune 3.20)
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
 (synopsis "Ml Paint")
 (description "Ml Paint")
 (depends ocaml tsdl ocaml-lsp-server wall tgls reason stb_truetype)
 (tags
  (ui graphics ocaml)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
