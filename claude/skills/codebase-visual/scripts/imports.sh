#!/usr/bin/env bash
# List every import as file<TAB>import text, for each language ast-grep knows.
# Usage: imports.sh <root> > imports.tsv
set -euo pipefail

root=${1:?usage: imports.sh <root>}
root=${root%/}  # repo/ would make the prefix repo// and match nothing
rules=""

rule() {
  local language=$1 matcher=$2
  rules+="---"$'\n'"{id: $language, language: $language, rule: $matcher}"$'\n'
}

# Static import, export-from, require() and dynamic import() sources.
js='{kind: string, any: [{inside: {kind: import_statement, field: source}}, {inside: {kind: export_statement, field: source}}, {inside: {kind: arguments, inside: {kind: call_expression, has: {field: function, regex: "^(require|import)$"}}}}]}'
for language in tsx typescript javascript; do rule "$language" "$js"; done
# Whole from-statements: deps.py joins the module with each imported name.
rule python '{any: [{kind: dotted_name, inside: {any: [{kind: import_statement}, {kind: aliased_import, inside: {kind: import_statement}}]}}, {kind: import_from_statement}]}'
rule go '{kind: interpreted_string_literal, inside: {kind: import_spec}}'
rule rust '{kind: use_declaration}'
for language in java swift scala; do rule "$language" '{kind: import_declaration}'; done
rule kotlin '{kind: import_header}'
rule csharp '{kind: using_directive}'
rule php '{kind: namespace_use_declaration}'
for language in c cpp; do rule "$language" '{kind: preproc_include}'; done
rule ruby '{kind: call, regex: "^require(_relative)?[ (]"}'
rule lua '{kind: function_call, regex: "^require[ (]"}'
rule dart '{kind: library_import}'
rule elixir '{kind: call, regex: "^(alias|import|require|use) [A-Z]"}'

# The = form: a value starting with --- would parse as a flag.
ast-grep scan --json=stream --inline-rules="$rules" "$root" \
  | jq -r --arg root "$root/" '[(.file | ltrimstr($root)), (.text | gsub("[\n\t]"; " "))] | @tsv'
