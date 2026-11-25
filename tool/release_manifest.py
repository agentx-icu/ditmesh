#!/usr/bin/env python3
"""Build an exact release inventory and synchronize static download fallbacks.

Checksums identify bytes, not a trusted publisher. No signature is inferred from
an extension. Only the Python standard library is required.
"""
import argparse
import datetime as dt
import html
import json
import os
from pathlib import Path
import re
import sys
import urllib.request

DEFAULT_REPOSITORY = "agentx-icu/ditmesh"
MANIFEST_NAME = "release-manifest.json"
MAX_JSON_BYTES = 2 * 1024 * 1024
REPOSITORIES = {"agentx-icu/" + name for name in ("toxee", "morsecq", "ditmesh")}
PACKAGE_EXTENSIONS = (".apk", ".aab", ".ipa", ".pkg", ".msi", ".deb", ".rpm", ".zip", ".tar.gz")


def _identity(repository, tag):
    if not isinstance(repository, str) or repository not in REPOSITORIES:
        raise ValueError("unsupported repository")
    if not isinstance(tag, str) or not re.fullmatch(r"v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?", tag):
        raise ValueError("release tag must be vMAJOR.MINOR.PATCH, optionally with a prerelease suffix")
    return repository.split("/")[1], tag[1:]


def _published_at(value):
    if value is None:
        return
    if not isinstance(value, str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", value):
        raise ValueError("published_at must be a UTC GitHub timestamp or null for a draft")
    dt.datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ")


def _platform(name):
    for pattern, value in ((r"-(?:Windows|windows)-", "windows"), (r"-(?:Darwin|macos)-", "macos"),
                           (r"-(?:Linux|linux)-", "linux"), (r"-(?:Android|android)(?:-|\.)", "android"),
                           (r"-(?:iOS|ios)(?:-|\.)", "ios")):
        if re.search(pattern, name):
            return value
    return None


def build_manifest(release, repository):
    """Normalize GitHub REST release data without including the manifest itself."""
    if not isinstance(release, dict) or not isinstance(release.get("assets"), list):
        raise ValueError("release must be an object with an asset list")
    _, version = _identity(repository, release.get("tag_name"))
    assets = []
    for asset in release.get("assets", []):
        if not isinstance(asset, dict):
            raise ValueError("release asset must be an object")
        name = asset.get("name")
        if name == MANIFEST_NAME:
            continue
        digest = asset.get("digest") or ""
        if not isinstance(digest, str):
            raise ValueError("asset digest must be a string or null")
        assets.append({"name": name, "url": asset.get("browser_download_url"), "size": asset.get("size"),
                       "sha256": digest.removeprefix("sha256:") if digest.startswith("sha256:") else None,
                       "platform": _platform(name) if isinstance(name, str) else None,
                       "signature_status": "unsigned" if isinstance(name, str) and "-unsigned." in name else "not_verified"})
    manifest = {"schema_version": 1, "repository": repository, "tag": release["tag_name"], "version": version,
                "release_url": release.get("html_url"), "published_at": release.get("published_at"),
                "draft": release.get("draft", False), "prerelease": release.get("prerelease", False),
                "assets": sorted(assets, key=lambda a: a["name"] or "")}
    validate_manifest(manifest)
    return manifest


def validate_manifest(manifest):
    if not isinstance(manifest, dict) or type(manifest.get("schema_version")) is not int or manifest["schema_version"] != 1:
        raise ValueError("unsupported release manifest schema")
    repository, tag = manifest.get("repository"), manifest.get("tag")
    app, version = _identity(repository, tag)
    if manifest.get("version") != version:
        raise ValueError("manifest version differs from tag")
    if manifest.get("release_url") != f"https://github.com/{repository}/releases/tag/{tag}":
        raise ValueError("release URL differs from repository/tag")
    for key in ("draft", "prerelease"):
        if type(manifest.get(key)) is not bool:
            raise ValueError(f"{key} must be a boolean")
    _published_at(manifest.get("published_at"))
    if not manifest["draft"] and manifest.get("published_at") is None:
        raise ValueError("a published release needs a publication date")
    assets = manifest.get("assets")
    if not isinstance(assets, list) or not assets:
        raise ValueError("release has no assets")
    seen = set()
    for asset in assets:
        if not isinstance(asset, dict):
            raise ValueError("invalid asset")
        name = asset.get("name")
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_.+-]+", name) or name == MANIFEST_NAME:
            raise ValueError("invalid release asset name")
        if name in seen:
            raise ValueError(f"duplicate asset: {name}")
        seen.add(name)
        if type(asset.get("size")) is not int or asset["size"] <= 0:
            raise ValueError(f"invalid asset size: {name}")
        if asset.get("url") != f"https://github.com/{repository}/releases/download/{tag}/{name}":
            raise ValueError(f"asset URL differs from repository/tag/name: {name}")
        sha = asset.get("sha256")
        if sha is not None and (not isinstance(sha, str) or not re.fullmatch(r"[0-9a-f]{64}", sha)):
            raise ValueError(f"invalid SHA-256: {name}")
        if name.endswith(PACKAGE_EXTENSIONS) and (not name.startswith(f"{app}-{version}-") or sha is None or _platform(name) is None):
            raise ValueError(f"package must belong to this version and have a platform and SHA-256: {name}")
        if asset.get("platform") != _platform(name):
            raise ValueError(f"asset platform differs from filename: {name}")
        status = "unsigned" if "-unsigned." in name else "not_verified"
        if asset.get("signature_status") != status:
            raise ValueError(f"signature status has no matching verification evidence: {name}")
    return manifest


def _read_json_response(url, authenticated=False):
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "agentx-release-manifest"}
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if authenticated and token:
        headers["Authorization"] = "Bearer " + token
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30) as response:
        body = response.read(MAX_JSON_BYTES + 1)
    if len(body) > MAX_JSON_BYTES:
        raise ValueError("release JSON exceeds 2 MiB")
    return json.loads(body)


def latest_manifest(repository):
    _identity(repository, "v0.0.0")
    release = _read_json_response(f"https://api.github.com/repos/{repository}/releases/latest", authenticated=True)
    expected = build_manifest(release, repository)
    published = [a for a in release["assets"] if a["name"] == MANIFEST_NAME]
    if published:
        manifest = validate_manifest(_read_json_response(published[0]["browser_download_url"]))
        if manifest != expected:
            raise ValueError("published manifest differs from release metadata; regenerate it first")
    else:
        manifest = expected  # Bootstrap releases predating manifest publication.
    return manifest


def _dump(value):
    return json.dumps(value, indent=2, ensure_ascii=False) + "\n"


def _size(value):
    return f"{value / 1048576:.1f} MB" if value >= 1048576 else f"{max(1, round(value / 1024))} KB"


def _one_asset(assets, suffix):
    matches = [a for a in assets if a["name"].endswith("-" + suffix)]
    if len(matches) != 1:
        raise ValueError(f"expected one asset ending in -{suffix}, found {len(matches)}")
    return matches[0]


def _fallback(manifest, app):
    tag, version = manifest["tag"], manifest["version"]
    if app == "toxee":
        rows = [f'      "{a["name"][len(f"{app}-{version}-"): ]}": [{a["size"]}, "{a["sha256"] or ""}"]'
                for a in manifest["assets"] if a["name"].startswith(f"{app}-{version}-")]
        lines = ["  var FALLBACK = {", f'    version: "{version}",', f'    tag: "{tag}",',
                 f'    date: "{manifest["published_at"][:10]}",', "    assets: {\n" + ",\n".join(rows) + "\n    }", "  };"]
        return "\n".join(lines)
    rows = [f"      ['{a['name']}', {a['size']}, '{'' if a['name'].startswith('SHA256SUMS') else (a['sha256'] or '')}']"
            for a in manifest["assets"]]
    return (f"  const FALLBACK = {{\n    tag_name: '{tag}',\n    name: 'DitMesh {tag}',\n"
            f"    published_at: '{manifest['published_at']}',\n    assets: [\n" + ",\n".join(rows) +
            f"\n    ].map(([name, size, sha]) => ({{\n      name, size,\n      digest: sha ? 'sha256:' + sha : '',\n"
            f"      browser_download_url: RELEASES + '/download/{tag}/' + name\n    }}))\n  }};")


def synchronize(root, manifest, write=False):
    """Prepare every edit before writing, so missing packages cannot half-sync a site."""
    validate_manifest(manifest)
    if manifest["draft"] or manifest["prerelease"]:
        raise ValueError("only a published stable release may update the stable website")
    root = Path(root).resolve()
    app, version = _identity(manifest["repository"], manifest["tag"])
    source = root / ("src/index.html" if app == "morsecq" else "index.html")
    src = source.read_text(encoding="utf-8")
    assets = manifest["assets"]
    by_name = {a["name"]: a for a in assets}
    prefix = f"{app}-{version}-"

    def current_asset(old_name):
        if old_name in by_name:
            return by_name[old_name]
        matches = [a for a in assets if a["name"].startswith(prefix) and old_name.endswith("-" + a["name"][len(prefix):])]
        if len(matches) != 1:
            raise ValueError(f"cannot resolve release asset {old_name}")
        return matches[0]

    def row(match):
        opening, suffix, body = match.groups()
        asset = _one_asset(assets, suffix)
        opening = re.sub(r'href="[^"]*"', 'href="' + asset["url"] + '"', opening)
        body, filenames = re.subn(r'(<span class="pf">)[^<]+', lambda m: m[1] + asset["name"], body)
        body, sizes = re.subn(r'(<span class="ps">)[^<]+', lambda m: m[1] + _size(asset["size"]), body)
        if filenames != 1 or sizes != 1:
            raise ValueError(f"download row for {suffix} has no unique name/size")
        return opening + body + "</a>"

    src = re.sub(r'(<a\b[^>]*class="pkg"[^>]*data-(?:pkg|asset)="([^"]+)"[^>]*>)(.*?)</a>', row, src, flags=re.S)
    src = re.sub(r'(<span\b[^>]*data-file="[^"]+"[^>]*>)([^<]+)', lambda m: m[1] + current_asset(m[2])["name"], src)
    url_pattern = r'https://github\.com/' + re.escape(manifest["repository"]) + r'/releases/(download|tag)/[^/"<>\s]+(?:/([^"<>\s]+))?'
    src = re.sub(url_pattern, lambda m: current_asset(m[2])["url"] if m[1] == "download" else manifest["release_url"], src)
    src = re.sub(r'(<(?:span|b)\b[^>]*\bdata-version(?:="[^"]*")?[^>]*>)[^<]+', lambda m: m[1] + manifest["tag"], src)
    src = re.sub(r'(<span\b[^>]*\bdata-release-date(?:="[^"]*")?[^>]*>)[^<]+', lambda m: m[1] + manifest["published_at"][:10], src)
    src = re.sub(r'("softwareVersion"\s*:\s*")[^"]+', lambda m: m[1] + version, src)
    if app == "morsecq":
        sums = "\n".join(a["sha256"] + "  " + a["name"] for a in assets if a["sha256"] and not a["name"].startswith("SHA256SUMS"))
        src, count = re.subn(r'(<pre\b[^>]*id="sums"[^>]*>).*?(</pre>)', lambda m: m[1] + html.escape(sums) + m[2], src, flags=re.S)
        if count != 1:
            raise ValueError("MorseCQ source needs one static checksum list")
    updates = {source: src, root / MANIFEST_NAME: _dump(manifest)}
    if app != "morsecq":
        js_path = root / ("assets/js/site.js" if app == "toxee" else "assets/main.js")
        js = js_path.read_text(encoding="utf-8")
        js, count = re.subn(r'  (?:var|const) FALLBACK = \{.*?\n  \};', lambda _: _fallback(manifest, app), js, count=1, flags=re.S)
        if count != 1:
            raise ValueError("site needs exactly one FALLBACK block")
        updates[js_path] = js
    changed = [p for p, content in updates.items() if not p.exists() or p.read_text(encoding="utf-8") != content]
    if write:
        for path in changed:
            path.write_text(updates[path], encoding="utf-8")
    return changed


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "sync", "check"))
    parser.add_argument("--repository", default=DEFAULT_REPOSITORY)
    parser.add_argument("--input", type=Path, help="REST release JSON for build; release manifest for sync/check")
    parser.add_argument("--output", type=Path, default=Path(MANIFEST_NAME))
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args(argv)
    args.root = args.root.resolve()
    try:
        if args.command == "build":
            if args.input is None:
                parser.error("build requires --input with GitHub REST release JSON")
            result = build_manifest(json.loads(args.input.read_text(encoding="utf-8")), args.repository)
            args.output.write_text(_dump(result), encoding="utf-8")
            print(f"Wrote {args.output}: {result['tag']}, {len(result['assets'])} assets; signatures are not attested")
        else:
            result = validate_manifest(json.loads(args.input.read_text(encoding="utf-8"))) if args.input else latest_manifest(args.repository)
            if result["repository"] != args.repository:
                raise ValueError("manifest belongs to a different repository")
            changed = synchronize(args.root, result, write=args.command == "sync")
            if changed and args.command == "check":
                print("Release fallback is out of sync: " + ", ".join(str(p.relative_to(args.root)) for p in changed), file=sys.stderr)
                return 1
            print(f"{result['tag']}: " + ("updated " + ", ".join(str(p.relative_to(args.root)) for p in changed) if changed else "release fallback matches"))
    except (ValueError, KeyError, TypeError, OSError) as error:
        print(f"Release manifest error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
