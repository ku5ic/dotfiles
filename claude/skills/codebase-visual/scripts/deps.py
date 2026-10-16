"""Module edges, externals and upward imports from a file<TAB>import-text list.

Usage: python3 -I deps.py <root> <imports.tsv> <out dir> [split dir]

Language agnostic. The import text may be a bare spec ("react", "./x") or a
whole statement ("use crate::a::b;", "#include <x.h>", "import static a.B.C;").
Specs are resolved against the repo's tracked files: relative paths, dotted
names, Rust and PHP paths with their {grouped, uses}, and Go module paths.
Whatever does not resolve to a tracked file or directory, or names a dependency
in a tracked manifest of the importing file's ecosystem, is an external package.

The split dir, unless given, is found by descending while one directory holds
over 80% of the importing files; its children become the modules.
"""

import collections
import functools
import json
import os
import posixpath
import re
import subprocess
import sys
import tomllib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
sys.dont_write_bytecode = True  # no __pycache__ in the dotfiles repo
from repo_paths import TEST_OR_STORY, module_stem

root, imports_path, out_dir, *override = sys.argv[1:]

KEYWORD = re.compile(
    r"^\s*(?:pub(?:\([^)]*\))?\s+)?"
    r"(?P<kw>#\s*include|import|using|use|alias|require_relative|require|from)(?:\s+|(?=[(\"'<]))"
    r"(?:static\s+)?"
)
CUT = re.compile(r"\s+as\s+|[;,\s()]")
SOURCE_FILE = re.compile(
    r"\.(h|hh|hpp|hxx|inc|c|cc|cpp|js|jsx|mjs|cjs|ts|tsx|json|css|scss|sass|less|vue|svelte"
    r"|rb|py|go|rs|php|dart|lua|graphql|gql|html|svg|png|md|ya?ml|wasm)$"
)
DOMAIN_ROOTS = {"com", "org", "net", "io", "dev", "edu", "gov", "co"}
ECOSYSTEM = dict.fromkeys((".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".mts", ".cts", ".vue", ".svelte"), "npm") | {
    ".py": "python", ".rs": "rust", ".rb": "ruby", ".go": "go",
}
# Languages whose specs are always dotted names, so `a.b.json` is a module, not a file.
DOTTED_LANGUAGES = {".py", ".java", ".kt", ".kts", ".cs", ".scala", ".groovy", ".lua", ".ex", ".exs"}
# NodeNext imports name the emitted file: ./a.js is a.ts.
JS_EMITTED = {".js", ".jsx", ".mjs", ".cjs"}
PYTHON_STDLIB = {name.lower() for name in sys.stdlib_module_names}
PLATFORM_ROOTS = {"java", "javax", "jakarta", "kotlin", "kotlinx", "android", "androidx", "scala", "System", "Microsoft"}


def expand_groups(text: str) -> list[str]:
    """a::{b, c::{d, e}} -> a::b, a::c::d, a::c::e; text without a group as is."""
    start = text.find("{")
    if start < 0:
        return [text]
    depth, items, item_start = 0, [], start + 1
    for index in range(start, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "," and depth == 1:
            items.append(text[item_start:index])
            item_start = index + 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                items.append(text[item_start:index])
                break
    return [spec for item in items if item.strip() for spec in expand_groups(text[:start] + item.strip())]


def python_from(text: str) -> list[str]:
    """`pkg import a, b as c` -> pkg.a, pkg.b; `. import x` -> .x. A name that is no module falls back to its package."""
    package, names = (part.strip() for part in text.split(" import ", 1))
    joiner = "" if package.endswith(".") else "."
    names = (name.split(" as ")[0].strip() for name in names.strip("() ").split(","))
    return [package if name == "*" else package + joiner + name for name in names if name]


def clean(text: str) -> list[tuple[str, bool]]:
    """Specs from an import statement or bare spec; True when one is file-relative."""
    text, keyword = text.strip(), ""
    if match := KEYWORD.match(text):
        # The ( of require("x") would otherwise cut the spec down to nothing.
        keyword, text = match["kw"], text[match.end():].lstrip("( ")
    if re.match(r"\w+\s*=", text):  # C# alias: using Json = Newtonsoft.Json;
        text = text.split("=", 1)[1].strip()
    quoted = text[:1] in "\"'"
    relative = keyword == "require_relative" or (keyword.startswith("#") and quoted)
    raw = python_from(text) if keyword == "from" and " import " in text else expand_groups(text)
    specs = (CUT.split(spec, maxsplit=1)[0].strip("\"'<>").removeprefix("package:") for spec in raw)
    return [(spec, relative) for spec in specs if spec]


def tracked_paths(files: list[str]) -> tuple[dict[str, str], dict[str, set[str]]]:
    """Lowercased stem or dir -> real path, and child name -> parent dirs."""
    known, parents = {}, collections.defaultdict(set)
    for file in files:
        stem = module_stem(file)
        for path in {file, stem}:
            known[path.lower()] = path
        parts = file.split("/")
        for depth in range(1, len(parts)):
            directory = "/".join(parts[:depth])
            known[directory.lower()] = directory
            parents[parts[depth - 1].lower()].add("/".join(parts[: depth - 1]).lower())
        stem_parts = stem.split("/")
        parents[stem_parts[-1].lower()].add("/".join(stem_parts[:-1]).lower())
    return known, parents


def package_key(requirement: str) -> str:
    """`PyYAML[ext]>=6` -> pyyaml; serde-json and serde_json compare equal."""
    return re.split(r"[\s<>=!~;\[]", requirement.strip(), maxsplit=1)[0].lower().replace("-", "_")


def registry_names(dependencies: object) -> list[str]:
    """Names in a dependency table, minus path and workspace entries: those live in this repo."""
    if not isinstance(dependencies, dict):
        return []
    return [
        name for name, spec in dependencies.items()
        if not (isinstance(spec, dict) and {"path", "workspace"} & spec.keys())
        and not str(spec).startswith(("workspace:", "file:", "link:", "portal:"))
    ]


def read_manifest(name: str, path: str) -> tuple[str, list[str]] | None:
    """Ecosystem and registry dependency names of one manifest, None for other files."""
    if name == "package.json":
        manifest = json.load(open(path))
        fields = ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies")
        return "npm", [n for field in fields for n in registry_names(manifest.get(field))]
    if name == "Cargo.toml":
        manifest = tomllib.load(open(path, "rb"))
        tables = [manifest.get(t) for t in ("dependencies", "dev-dependencies", "build-dependencies")]
        tables.append(manifest.get("workspace", {}).get("dependencies"))
        return "rust", [n for table in tables for n in registry_names(table)]
    if name == "pyproject.toml":
        manifest = tomllib.load(open(path, "rb"))
        project, tool = manifest.get("project", {}), manifest.get("tool", {})
        requirements = list(project.get("dependencies", []))
        requirements += [r for group in project.get("optional-dependencies", {}).values() for r in group]
        local = {package_key(n) for n in tool.get("uv", {}).get("sources", {})}
        names = [r for r in requirements if package_key(r) not in local]
        return "python", names + registry_names(tool.get("poetry", {}).get("dependencies"))
    if re.fullmatch(r"requirements.*\.txt", name):
        return "python", [line for line in open(path) if line.strip() and not line.lstrip().startswith(("#", "-", ".", "/"))]
    if name == "Gemfile":
        return "ruby", re.findall(r"^\s*gem\s+['\"]([^'\"]+)", open(path).read(), re.MULTILINE)
    if name == "go.mod":
        return "go", re.findall(r"^\s*(?:require\s+)?([^\s()]+)\s+v\d\S*", open(path).read(), re.MULTILINE)
    return None


def declared_packages(files: list[str]) -> dict[str, set[str]]:
    """Registry dependencies per ecosystem, so src/graphql never shadows the `graphql` package."""
    declared = collections.defaultdict(set)
    for file in files:
        try:
            found = read_manifest(posixpath.basename(file), os.path.join(root, file))
        except (OSError, ValueError, AttributeError):  # unreadable or oddly shaped manifest
            continue
        if found:
            ecosystem, names = found
            # A Go module path keeps its dashes: it is matched as a path prefix.
            declared[ecosystem].update(n.lower() if ecosystem == "go" else package_key(n) for n in names)
    return declared


def go_modules(files: list[str]) -> list[tuple[str, str]]:
    """(module path, its dir) for every tracked go.mod, the longest path first so nested modules win."""
    modules = []
    for file in files:
        if posixpath.basename(file) == "go.mod":
            if found := re.search(r"^module\s+(\S+)", open(os.path.join(root, file)).read(), re.MULTILINE):
                modules.append((found[1], posixpath.dirname(file)))
    return sorted(modules, key=lambda module: -len(module[0]))


def dart_packages(files: list[str]) -> dict[str, str]:
    """Package name -> lib dir for every tracked pubspec.yaml: package:<name>/x is <dir>/lib/x."""
    packages = {}
    for file in files:
        if posixpath.basename(file) == "pubspec.yaml":
            if found := re.search(r"^name:\s*['\"]?([\w-]+)", open(os.path.join(root, file)).read(), re.MULTILINE):
                packages[found[1].lower()] = posixpath.join(posixpath.dirname(file), "lib")
    return packages


def snake_case(name: str) -> str:
    """Elixir module to file name: MyApp.HTTPClient -> my_app.http_client."""
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", "_", name).lower()


def crate_src(file: str) -> str:
    """The src dir of the nearest Cargo crate above a file, else src."""
    directory = posixpath.dirname(file)
    while directory:
        if posixpath.join(directory, "Cargo.toml").lower() in known:
            return posixpath.join(directory, "src")
        directory = posixpath.dirname(directory)
    return "src"


def normalize(file: str, spec: str) -> tuple[str, str]:
    """Path-like spec and how to resolve it: relative, rooted (to the repo), dotted, or plain."""
    spec = spec.split("?")[0]
    language = os.path.splitext(file)[1]
    python_relative = re.match(r"^(\.+)([^./].*)?$", spec)
    if python_relative and "/" not in spec:
        dots, rest = python_relative.group(1), python_relative.group(2) or ""
        up = "./" if len(dots) == 1 else "../" * (len(dots) - 1)
        return up + rest.replace(".", "/"), "relative"
    for module, directory in modules:
        if spec == module or spec.startswith(module + "/"):
            return posixpath.join(directory, spec[len(module):].lstrip("/")).rstrip("/"), "rooted"
    if language in (".ex", ".exs"):
        spec = snake_case(spec)
    spec = spec.replace("::", "/").replace("\\", "/").lstrip("/")
    head, _, tail = spec.partition("/")
    if language == ".dart" and head.lower() in dart_libs:
        return posixpath.join(dart_libs[head.lower()], tail), "rooted"
    if head == "crate":
        return posixpath.join(crate_src(file), tail), "rooted"
    if head in ("self", "super"):
        # From src/net/client.rs, self is src/net/client; from a crate root or mod.rs, it is the dir.
        base = os.path.splitext(file)[0]
        if posixpath.basename(base) in ("lib", "main", "mod"):
            base = posixpath.dirname(base)
        while head in ("self", "super"):
            if head == "super":
                base = posixpath.dirname(base)
            head, _, tail = tail.partition("/")
        return posixpath.join(base, head, tail).rstrip("/"), "rooted"
    # A dot in a JS spec is part of a package name (socket.io-client), never a separator.
    may_be_dotted = ECOSYSTEM.get(language) != "npm" and (language in DOTTED_LANGUAGES or not SOURCE_FILE.search(spec))
    if "/" not in spec and "." in spec.strip(".") and may_be_dotted:
        return spec.replace(".", "/"), "dotted"
    return spec, "plain"


def longest_existing(base: str, rel: str) -> str | None:
    """Longest tracked path base/rel[:k], never shorter than one segment of rel."""
    segments = [s for s in rel.split("/") if s]
    for k in range(len(segments), 0, -1):
        candidate = posixpath.join(base, *segments[:k])
        if candidate.lower() in known:
            return known[candidate.lower()]
    return None


def external_name(path: str, kind: str) -> str:
    parts = [p for p in path.split("/") if p]
    dotted = kind == "dotted"
    if not parts:
        return path
    if path.startswith("@") or (dotted and parts[0] in PLATFORM_ROOTS):
        name = parts[:2]
    elif (dotted and parts[0] in DOMAIN_ROOTS) or (not dotted and "." in parts[0]):
        name = parts[:3]
    else:
        name = parts[:1]
    return ("." if dotted else "/").join(name)


def find_split(files: list[str]) -> str:
    prefix = ""
    while True:
        inside = [f[len(prefix):] for f in files if f.startswith(prefix)]
        children = collections.Counter(f.split("/")[0] for f in inside if "/" in f)
        if not children:
            return prefix.rstrip("/")
        child, count = children.most_common(1)[0]
        if count / len(inside) <= 0.8:
            return prefix.rstrip("/")
        prefix += child + "/"


rows = [line.rstrip("\n").split("\t", 1) for line in open(imports_path) if "\t" in line]
tracked = list(filter(None, subprocess.run(["git", "-C", root, "ls-files"], capture_output=True, text=True, check=True).stdout.split("\n")))
known, parents = tracked_paths(tracked)
declared = declared_packages(tracked)
modules = go_modules(tracked)
dart_libs = dart_packages(tracked)
if override:
    split = posixpath.normpath(override[0]).strip("/")  # src/ and ./src name the same dir
    split = "" if split == "." else split
else:
    split = find_split(sorted({file for file, _ in rows}))


children_of_split = {
    path[len(split) + 1:].split("/")[0]
    for path in known.values()
    if split and path.startswith(split + "/") and "/" in path[len(split) + 1:]
}


def module_of(path: str) -> str:
    if split and path.startswith(split + "/"):
        child = path[len(split) + 1:].split("/")[0]
        return f"{split}/{child}" if child in children_of_split else split
    return path.split("/")[0]


specs = []
for file, text in rows:
    for spec, file_relative in clean(text):
        path, kind = normalize(file, spec)
        if file_relative and not path.startswith("."):
            path = "./" + path
        specs.append((file, path, kind))

# Source roots: directories whose children are named by the first segment of
# bare specs. A real root (src, src/main/java) explains several distinct
# segments; a folder that merely shares a package's name explains one.
root_votes = collections.Counter()
root_segments = collections.defaultdict(set)
for _, path, kind in specs:
    if kind in ("dotted", "plain"):
        head = path.split("/")[0].lower()
        for parent in parents.get(head, ()):
            root_votes[parent] += 1
            root_segments[parent].add(head)
roots = sorted(root_votes, key=lambda r: (-len(root_segments[r]), -root_votes[r]))
root_rank = {source_root: rank for rank, source_root in enumerate(roots)}


def resolve(file: str, path: str, kind: str) -> str | None:
    """Repo path an import points at, None for an external package."""
    directory = posixpath.dirname(file)
    if path.startswith("."):
        joined = posixpath.normpath(posixpath.join(directory, path))
        stem, extension = posixpath.splitext(joined)
        if joined.lower() not in known and extension in JS_EMITTED and stem.lower() in known:
            return known[stem.lower()]
        return longest_existing("", joined) or joined
    if kind == "rooted":
        return longest_existing("", path) or path
    ecosystem = ECOSYSTEM.get(os.path.splitext(file)[1])
    if ecosystem == "go":
        return None  # Go's own packages sit under a go.mod module path, matched as rooted
    if SOURCE_FILE.search(path) and (hit := longest_existing(directory, path)):
        return hit
    return resolve_bare(path, kind, ecosystem)


def is_declared(path: str, kind: str, ecosystem: str | None) -> bool:
    if ecosystem == "go":  # a go.mod require names a module, the import a package inside it
        return any(path.lower() == m or path.lower().startswith(m + "/") for m in declared["go"])
    return package_key(external_name(path, kind)) in declared.get(ecosystem, ())


@functools.cache
def resolve_bare(path: str, kind: str, ecosystem: str | None) -> str | None:
    """A bare spec against the source roots; the same `react` or `fmt` repeats thousands of times."""
    head = path.split("/")[0].lower()
    if is_declared(path, kind, ecosystem) or (ecosystem == "python" and head in PYTHON_STDLIB):
        return None
    # Only a root holding the spec's first segment can match.
    candidates = sorted(parents.get(head, set()) & root_rank.keys(), key=root_rank.get)
    # The deepest match wins (lua/net/http over src/net for net.http); a tie goes to the higher-ranked root.
    best, best_depth = None, 0
    for source_root in candidates:
        base = known.get(source_root, source_root)
        if not (hit := longest_existing(base, path)):
            continue
        # Past the main root, a one-segment match is a folder sharing a package's
        # name (src/components/form/graphql vs "graphql"), not a real import.
        depth = len(hit.split("/")) - (len(base.split("/")) if base else 0)
        if (root_rank[source_root] == 0 or depth >= 2) and depth > best_depth:
            best, best_depth = hit, depth
    return best


edges = collections.Counter()
prod_files = collections.defaultdict(collections.Counter)
externals = collections.Counter()
declared_externals = set()
resolved = []
for file, path, kind in specs:
    target_path = resolve(file, path, kind)
    if target_path is None:
        name = external_name(path, kind)
        externals[name] += 1
        if is_declared(path, kind, ECOSYSTEM.get(os.path.splitext(file)[1])):
            declared_externals.add(name)
        continue
    resolved.append((file, target_path))
    source, target = module_of(file), module_of(target_path)
    if source != target:
        edges[(source, target)] += 1
        if not TEST_OR_STORY.search(file):
            prod_files[(source, target)][file] += 1

with open(os.path.join(out_dir, "deps.tsv"), "w") as out:
    for (source, target), count in edges.most_common():
        out.write(f"{count}\t{source}\t{target}\n")

with open(os.path.join(out_dir, "externals.tsv"), "w") as out:
    for name, count in externals.most_common():
        out.write(f"{count}\t{name}\t{'declared' if name in declared_externals else 'undeclared'}\n")

# An edge is upward when the reverse direction carries more production imports.
# Tests and stories don't vote: they often import upward legitimately.
with open(os.path.join(out_dir, "upward.tsv"), "w") as out:
    out.write("imports\tprod_imports\tprod_files\tsource\ttarget\ttop_prod_files\n")
    for (source, target), count in edges.most_common():
        files = prod_files[(source, target)]
        prod = files.total()
        if not prod or prod_files[(target, source)].total() <= prod:
            continue
        top = ",".join(f for f, _ in files.most_common(5))
        out.write(f"{count}\t{prod}\t{len(files)}\t{source}\t{target}\t{top}\n")

with open(os.path.join(out_dir, "imports-resolved.tsv"), "w") as out:
    for file, target_path in resolved:
        out.write(f"{file}\t{target_path}\n")

main_root = (roots[0] or "(repo root)") if roots else "none"
print(f"split dir: {split or '(repo root)'}; main source root: {main_root}; other candidates: {max(0, len(roots) - 1)}")
