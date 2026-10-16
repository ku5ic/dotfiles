"""Files that change together, from `git log --format='--%H ...' --name-only`.

Usage: python3 -I coupling.py <gitlog.txt> <imports-resolved.tsv> <out.tsv>
Skips bulk commits, generated, lock, manifest, CI, test and story files, and pairs in the same directory.
Writes shared commits, coupling degree, whether either file imports the other, and both paths.
"""

import collections
import itertools
import os
import posixpath
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
sys.dont_write_bytecode = True  # no __pycache__ in the dotfiles repo
from repo_paths import TEST_OR_STORY, module_stem as stem

log_path, resolved_path, out_path = sys.argv[1:]
MAX_FILES_PER_COMMIT = 30
MIN_SHARED = 5
# Data files stay in (flags.json, routes.yaml are the registries hidden coupling exposes); manifests,
# CI and lock files change alongside everything.
NOISE = re.compile(
    r"\.snap$|\.lock$|-lock\.|go\.(sum|mod)$|generated|\.(md|svg|css|scss|txt)$|(^|/)\.github/"
    r"|(^|/)(package|composer|tsconfig[^/]*)\.json$|(^|/)(Cargo|pyproject)\.toml$|(^|/)pubspec\.yaml$"
)

commits, current = [], []
for line in open(log_path):
    line = line.strip()
    if line.startswith("--"):
        if current:
            commits.append(current)
        current = []
    elif line and not NOISE.search(line) and not TEST_OR_STORY.search(line):
        current.append(line)
if current:
    commits.append(current)

changes = collections.Counter()
pairs = collections.Counter()
for files in commits:
    if len(files) > MAX_FILES_PER_COMMIT:
        continue
    changes.update(files)
    for a, b in itertools.combinations(sorted(set(files)), 2):
        if posixpath.dirname(a) != posixpath.dirname(b):
            pairs[(a, b)] += 1

imports = set()
for line in open(resolved_path):
    file, target = line.rstrip("\n").split("\t")
    imports.add((stem(file), stem(target)))

with open(out_path, "w") as out:
    frequent = collections.Counter({pair: shared for pair, shared in pairs.items() if shared >= MIN_SHARED})
    for (a, b), shared in frequent.most_common():
        degree = shared / min(changes[a], changes[b])
        linked = (stem(a), stem(b)) in imports or (stem(b), stem(a)) in imports
        out.write(f"{shared}\t{degree:.2f}\t{'imports' if linked else 'no-import'}\t{a}\t{b}\n")
