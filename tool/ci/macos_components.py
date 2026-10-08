#!/usr/bin/env python3
"""Keep Installer updates inside /Applications/DitMesh.app."""
import copy
from pathlib import Path
import plistlib
import sys


def configure_components(entries):
    roots = [copy.deepcopy(entry) for entry in entries
             if entry.get("RootRelativeBundlePath") == "DitMesh.app"]
    if len(roots) != 1:
        raise ValueError("Expected exactly one DitMesh.app installer component")

    def restrict_location(bundle):
        bundle["BundleIsRelocatable"] = False
        for child in bundle.get("ChildBundles", []):
            restrict_location(child)

    restrict_location(roots[0])
    roots[0]["BundleHasStrictIdentifier"] = True
    return roots


def main():
    path = Path(sys.argv[1])
    with path.open("rb") as source:
        result = configure_components(plistlib.load(source))
    temporary = path.with_suffix(".tmp.plist")
    with temporary.open("wb") as output:
        plistlib.dump(result, output)
    temporary.replace(path)


if __name__ == "__main__":
    main()
