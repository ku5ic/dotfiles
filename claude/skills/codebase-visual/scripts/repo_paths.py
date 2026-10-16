"""Path rules deps.py and coupling.py must agree on."""

import os
import re

TEST_OR_STORY = re.compile(
    r"(^|/)(tests?|spec|__tests__|mocks?|testdata|fixtures|stories)/"
    r"|[._-](test|spec|stories)\.[^/]+$|(^|/)test_[^/]+$|Tests?\.[A-Za-z]+$"
)


def module_stem(path: str) -> str:
    """What an import of this file names: no extension, no index, __init__ or mod.rs."""
    stem = os.path.splitext(path)[0]
    for name in ("/index", "/__init__", "/mod"):
        stem = stem.removesuffix(name)
    return stem
