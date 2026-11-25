import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

from release_manifest import build_manifest, validate_manifest, synchronize


def release(app="toxee", version="2.3.4"):
    tag = "v" + version
    suffix = {"toxee": "Windows-AMD64.msi", "morsecq": "windows-x64.msi", "ditmesh": "windows-x64.msi"}[app]
    name = f"{app}-{version}-{suffix}"
    return {"tag_name": tag, "name": app + " " + tag,
            "html_url": f"https://github.com/agentx-icu/{app}/releases/tag/{tag}",
            "published_at": "2026-11-25T01:02:03Z", "draft": False, "prerelease": False,
            "assets": [{"name": name, "size": 2468101, "digest": "sha256:" + "a" * 64,
                        "browser_download_url": f"https://github.com/agentx-icu/{app}/releases/download/{tag}/{name}"}]}


class ManifestTests(unittest.TestCase):
    def test_malformed_release_shapes_are_rejected_cleanly(self):
        for candidate in [[], {}, {"assets": {}}, {**release(), "assets": ["bad"]},
                          {**release(), "assets": [{**release()["assets"][0], "digest": {"bad": True}}]}]:
            with self.subTest(candidate=candidate), self.assertRaises(ValueError):
                build_manifest(candidate, "agentx-icu/toxee")

    def test_unknown_schema_and_unearned_signature_claims_are_rejected(self):
        manifest = build_manifest(release(), "agentx-icu/toxee")
        for mutate in [lambda m: m.update(schema_version=True),
                       lambda m: m.update(repository=[]),
                       lambda m: m["assets"][0].update(signature_status="verified")]:
            candidate = copy.deepcopy(manifest)
            mutate(candidate)
            with self.assertRaises(ValueError):
                validate_manifest(candidate)

    def test_hash_and_origin_are_bound_to_exact_release(self):
        manifest = build_manifest(release(), "agentx-icu/toxee")
        self.assertIsInstance(manifest, dict)
        self.assertEqual(manifest["assets"][0]["sha256"], "a" * 64)
        self.assertEqual(manifest["assets"][0]["signature_status"], "not_verified")
        for field, value in [("sha256", "bad"), ("url", "https://evil.invalid/file"), ("size", -1)]:
            candidate = copy.deepcopy(manifest)
            candidate["assets"][0][field] = value
            with self.assertRaises(ValueError):
                validate_manifest(candidate)

    def test_missing_hash_duplicate_name_and_wrong_version_are_rejected(self):
        for mutate in [lambda r: r["assets"][0].pop("digest"),
                       lambda r: r["assets"].append(copy.deepcopy(r["assets"][0])),
                       lambda r: r["assets"][0].update(name="toxee-1.0.0-Windows-AMD64.msi")]:
            candidate = release()
            mutate(candidate)
            with self.assertRaises(ValueError):
                build_manifest(candidate, "agentx-icu/toxee")

    def test_manifest_asset_is_excluded_to_avoid_self_hash(self):
        candidate = release()
        candidate["assets"].append({"name": "release-manifest.json"})
        self.assertEqual(len(build_manifest(candidate, "agentx-icu/toxee")["assets"]), 1)

    def test_real_github_draft_url_is_normalized_without_claiming_publication(self):
        candidate = release()
        candidate.update(draft=True, published_at=None,
                         html_url="https://github.com/agentx-icu/toxee/releases/tag/untagged-08ac23b51ef506ac0164")
        candidate["assets"][0]["browser_download_url"] = candidate["assets"][0]["browser_download_url"].replace(
            "/download/v2.3.4/", "/download/untagged-08ac23b51ef506ac0164/")
        manifest = build_manifest(candidate, "agentx-icu/toxee")
        self.assertTrue(manifest["draft"])
        self.assertIsNone(manifest["published_at"])
        self.assertEqual(manifest["release_url"], "https://github.com/agentx-icu/toxee/releases/tag/v2.3.4")
        self.assertIn("/download/v2.3.4/", manifest["assets"][0]["url"])
        candidate["assets"][0]["browser_download_url"] = candidate["assets"][0]["browser_download_url"].replace(
            "untagged-08ac23b51ef506ac0164", "untagged-unrelated")
        with self.assertRaises(ValueError):
            build_manifest(candidate, "agentx-icu/toxee")

    def test_draft_or_prerelease_cannot_change_stable_site(self):
        for key in ["draft", "prerelease"]:
            candidate = release()
            candidate[key] = True
            with tempfile.TemporaryDirectory() as d:
                with self.assertRaises(ValueError):
                    synchronize(Path(d), build_manifest(candidate, "agentx-icu/toxee"), write=True)
                self.assertEqual(list(Path(d).iterdir()), [])

    def test_sync_updates_offline_rows_commands_dates_and_jsonld_together(self):
        for app in ["toxee", "morsecq", "ditmesh"]:
            with self.subTest(app=app), tempfile.TemporaryDirectory() as d:
                root = Path(d)
                source = root / ("src/index.html" if app == "morsecq" else "index.html")
                source.parent.mkdir(parents=True, exist_ok=True)
                suffix = "Windows-AMD64.msi" if app == "toxee" else "windows-x64.msi"
                old = f"{app}-1.0.0-{suffix}"
                source.write_text(f'''<b data-version>v1.0.0</b><span data-release-date>2026-01-01</span>
<small class="hero-dl-sub" data-version>v1.0.0</small>
<small id="heroDlSub"><span lang="en"><span data-version>v1.0.0</span> · free</span><span lang="zh"><span data-version>v1.0.0</span> · 免费</span></small>
<script type="application/ld+json">{{"softwareVersion": "1.0.0"}}</script>
<a class="pkg" data-asset="{suffix}" href="https://github.com/agentx-icu/{app}/releases/download/v1.0.0/{old}"><span class="pf">{old}</span><span class="ps">1 MB</span></a>
<span data-file="{suffix}">{old}</span>
<pre class="sums" id="sums">old</pre>''')
                js = root / ("assets/js/site.js" if app == "toxee" else "assets/main.js")
                js.parent.mkdir(parents=True, exist_ok=True)
                declaration = "var" if app == "toxee" else "const"
                js.write_text(f"  {declaration} FALLBACK = {{ old: true\n  }};\n")
                manifest = build_manifest(release(app), "agentx-icu/" + app)
                synchronize(root, manifest, write=True)
                text = source.read_text()
                self.assertIn("v2.3.4", text)
                self.assertIn("2026-11-25", text)
                self.assertIn("2.4 MB", text)
                self.assertNotIn(old, text)
                self.assertNotIn("v1.0.0", text)
                self.assertIn("· free", text)
                self.assertIn("· 免费", text)
                self.assertIn('"softwareVersion": "2.3.4"', text)
                self.assertEqual(json.loads((root / "release-manifest.json").read_text()), manifest)
                before = {str(p.relative_to(root)): p.read_bytes() for p in root.rglob("*") if p.is_file()}
                synchronize(root, manifest, write=True)
                self.assertEqual(before, {str(p.relative_to(root)): p.read_bytes() for p in root.rglob("*") if p.is_file()})

    def test_missing_required_package_leaves_every_file_unchanged(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            source = root / "index.html"
            source.write_text('<a class="pkg" data-pkg="Android-arm64.apk" href="old"><span class="pf">old</span><span class="ps">1 MB</span></a>')
            before = source.read_bytes()
            with self.assertRaises(ValueError):
                synchronize(root, build_manifest(release(), "agentx-icu/toxee"), write=True)
            self.assertEqual(source.read_bytes(), before)
            self.assertFalse((root / "release-manifest.json").exists())


if __name__ == "__main__":
    unittest.main()
