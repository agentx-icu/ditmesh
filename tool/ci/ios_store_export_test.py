import datetime
import hashlib
import importlib.util
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(__file__).with_name("ios_store_export.py")
spec = importlib.util.spec_from_file_location("ios_store_export", SOURCE)
store = importlib.util.module_from_spec(spec)
spec.loader.exec_module(store)


class IosStoreExportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ditmesh iOS export ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.certificate = b"test certificate bytes, not a signing identity"
        self.fingerprint = hashlib.sha1(self.certificate).hexdigest().upper()
        self.options = {"method": "app-store-connect", "destination": "export",
                        "signingStyle": "manual", "teamID": "ABCDE12345",
                        "signingCertificate": self.fingerprint,
                        "provisioningProfiles": {"icu.agentx.ditmesh": "owner-profile"}}
        self.path = self.root / "ExportOptions.plist"

    def options_check(self):
        self.path.write_bytes(plistlib.dumps(self.options))
        return store.export_options(self.path, "ABCDE12345", self.fingerprint)

    def profile(self):
        return {"UUID": "fixture", "TeamIdentifier": ["ABCDE12345"],
                "ExpirationDate": datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
                + datetime.timedelta(days=1), "DeveloperCertificates": [self.certificate],
                "Entitlements": {"application-identifier": "PREFIX.icu.agentx.ditmesh",
                                 "com.apple.developer.team-identifier": "ABCDE12345",
                                 "get-task-allow": False}}

    def test_accepts_only_explicit_local_manual_export(self):
        self.assertEqual(self.options_check()["destination"], "export")
        for key, value in (("destination", "upload"), ("signingStyle", "automatic"),
                           ("method", "release-testing"), ("teamID", "OTHER12345"),
                           ("signingCertificate", "Apple Distribution")):
            with self.subTest(key=key):
                previous = self.options[key]
                self.options[key] = value
                with self.assertRaises(ValueError):
                    self.options_check()
                self.options[key] = previous

    def test_missing_export_destination_and_unreviewed_extra_profiles_rejected(self):
        self.options.pop("destination")
        with self.assertRaises(ValueError):
            self.options_check()
        self.options["destination"] = "export"
        self.options["provisioningProfiles"]["com.other.app"] = "other"
        with self.assertRaises(ValueError):
            self.options_check()

    def test_profile_matches_explicit_app_certificate_team_and_expiry(self):
        profile = self.profile()
        entitlement = dict(profile["Entitlements"])
        self.assertEqual(store.profile_evidence(profile, entitlement, "ABCDE12345", self.fingerprint)["uuid"], "fixture")
        with self.assertRaisesRegex(ValueError, "selected profile"):
            store.profile_evidence(profile, entitlement, "ABCDE12345", self.fingerprint, "wrong-profile")
        cases = [({"ProvisionedDevices": ["device"]}, "device"),
                 ({"ProvisionsAllDevices": True}, "enterprise"),
                 ({"ExpirationDate": datetime.datetime(2000, 1, 1)}, "expired"),
                 ({"TeamIdentifier": ["OTHER12345"]}, "team"),
                 ({"DeveloperCertificates": [b"other"]}, "certificate")]
        for update, message in cases:
            with self.subTest(message=message), self.assertRaises(ValueError):
                store.profile_evidence({**profile, **update}, entitlement, "ABCDE12345", self.fingerprint)

    def test_debug_wildcard_and_mismatched_application_entitlements_rejected(self):
        for key, value in (("get-task-allow", True), ("application-identifier", "PREFIX.*"),
                           ("application-identifier", "PREFIX.com.other.app"),
                           ("com.apple.developer.team-identifier", "OTHER12345")):
            with self.subTest(key=key, value=value):
                profile = self.profile()
                profile["Entitlements"][key] = value
                with self.assertRaises(ValueError):
                    store.profile_evidence(profile, profile["Entitlements"], "ABCDE12345", self.fingerprint)
        profile = self.profile()
        with self.assertRaises(ValueError):
            store.profile_evidence(profile, {**profile["Entitlements"], "application-identifier": "OTHER.icu.agentx.ditmesh"},
                                   "ABCDE12345", self.fingerprint)

    def test_archive_and_export_commands_cannot_register_or_upload(self):
        archive, export = store.commands(self.root, self.root / "output", self.path)
        self.assertIn("CODE_SIGNING_ALLOWED=NO", archive)
        self.assertIn("archive", archive)
        self.assertIn("-exportArchive", export)
        for command in (archive, export):
            self.assertNotIn("-allowProvisioningUpdates", command)
            self.assertNotIn("-allowProvisioningDeviceRegistration", command)
        self.assertIn(str(self.root / "apps/ditmesh/ios/Runner.xcworkspace"), archive)

    def test_submission_toolchain_accepts_current_complete_versions(self):
        for sdk, xcode in (("iphoneos26", "2600"), ("iphoneos26.0", "2600"),
                           ("iphoneos26.5", "2660"), ("iphoneos26.5.1", "2661"),
                           ("iphoneos27.0", "2700")):
            with self.subTest(sdk=sdk, xcode=xcode):
                store.submission_toolchain({"DTSDKName": sdk, "DTXcode": xcode})

    def test_submission_toolchain_rejects_pre_april_2026_floor_and_independent_mismatch(self):
        for sdk, xcode in (("iphoneos18.5", "1640"), ("iphoneos18.5", "2660"),
                           ("iphoneos26.5", "1640"), ("iphoneos25.9", "2599")):
            with self.subTest(sdk=sdk, xcode=xcode), self.assertRaisesRegex(ValueError, "iOS 26.*Xcode 26"):
                store.submission_toolchain({"DTSDKName": sdk, "DTXcode": xcode})

    def test_submission_toolchain_rejects_missing_malformed_or_simulator_metadata(self):
        for sdk in (None, "", 26, True, "iphoneos", "iphoneos26beta", "iphoneos26.5suffix",
                    "iphoneos26.", "iphoneos026.5", "iphonesimulator26.5", " iphoneos26.5"):
            with self.subTest(sdk=sdk), self.assertRaisesRegex(ValueError, "SDK"):
                store.submission_toolchain({"DTSDKName": sdk, "DTXcode": "2660"})
        for xcode in (None, "", 2660, True, "26.6", "266", "26600", "2660beta", " 2660", "02660"):
            with self.subTest(xcode=xcode), self.assertRaisesRegex(ValueError, "Xcode"):
                store.submission_toolchain({"DTSDKName": "iphoneos26.5", "DTXcode": xcode})

    def test_signing_authority_must_be_distribution_not_development(self):
        self.assertEqual(store.distribution_authority("Authority=Apple Distribution: Owner (ABCDE12345)\nAuthority=Apple Root CA"),
                         "Apple Distribution: Owner (ABCDE12345)")
        for display in ("Signature=adhoc", "Authority=Apple Development: Owner (ABCDE12345)", ""):
            with self.subTest(display=display), self.assertRaises(ValueError):
                store.distribution_authority(display)

    def test_existing_output_is_rejected_before_any_build_command(self):
        with patch.object(store, "run") as runner:
            with self.assertRaises(FileExistsError):
                store.build(self.root, self.root, None, None, None, True)
            runner.assert_not_called()

    def test_actual_signer_mismatch_cannot_produce_distribution_evidence(self):
        (self.root / "ipa").mkdir()
        (self.root / "ipa/App.ipa").write_bytes(b"fixture, not an exported application")
        def runner(command, **kwargs):
            result = subprocess.CompletedProcess(command, 0, stdout=b"", stderr=b"")
            if command[0] == "ditto":
                (Path(command[-1]) / "Payload/Runner.app").mkdir(parents=True)
            elif "--verbose=4" in command:
                result.stderr = "Authority=Apple Distribution: Owner (ABCDE12345)\n"
            elif "--entitlements" in command:
                result.stdout = plistlib.dumps(self.profile()["Entitlements"])
            elif command[:2] == ["security", "cms"]:
                result.stdout = plistlib.dumps(self.profile())
            elif "--extract-certificates" in command:
                Path(command[-2] + "0").write_bytes(b"different actual signer")
            return result
        with patch.object(store, "run", side_effect=runner), patch.object(store, "inspect_app"):
            with self.assertRaisesRegex(ValueError, "Actual exported app signer"):
                store.inspect_export(self.root, self.root, "ABCDE12345", self.fingerprint, "fixture")
        self.assertFalse((self.root / "export-evidence/distribution.json").exists())

    def test_wrapper_rejects_unreviewed_xcode_and_flutter_overrides(self):
        wrapper = SOURCE.parents[1] / "build_ios_store.sh"
        for argument in ("-allowProvisioningUpdates", "-allowProvisioningDeviceRegistration",
                         "--export-method=app-store", "CODE_SIGN_STYLE=Automatic"):
            with self.subTest(argument=argument):
                result = subprocess.run(["bash", str(wrapper), argument], capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertIn("unrecognized arguments", result.stderr)

    def test_export_policy_is_snapshotted_before_commands(self):
        self.options_check()
        calls = []
        def runner(command, **kwargs):
            calls.append((command, kwargs.get("cwd")))
            if len(calls) == 1:
                self.options["destination"] = "upload"
                self.path.write_bytes(plistlib.dumps(self.options))
        output = self.root / "snapshot"
        with patch.object(store, "run", side_effect=runner), patch.object(store, "inspect_archive"), \
                patch.object(store, "inspect_export"):
            store.build(self.root, output, self.path, "ABCDE12345", self.fingerprint, False)
        archive, exported = calls[2][0], calls[3][0]
        self.assertIn(str(self.root / "apps/ditmesh/ios/Runner.xcworkspace"), archive)
        self.assertEqual(calls[1][1], self.root / "apps/ditmesh")
        self.assertIn("--no-codesign", calls[1][0])
        self.assertIn("--config-only", calls[1][0])
        self.assertIn("--dart-define=DITMESH_FAKE_BACKEND=false", calls[1][0])
        snapshot = Path(exported[exported.index("-exportOptionsPlist") + 1])
        self.assertNotEqual(snapshot, self.path)
        self.assertEqual(plistlib.loads(snapshot.read_bytes())["destination"], "export")

    def test_nested_signed_targets_are_rejected_before_native_inspection(self):
        app = self.root / "Runner.app"
        (app / "PlugIns/Unreviewed.appex").mkdir(parents=True)
        (app / "Info.plist").write_bytes(plistlib.dumps({"CFBundleExecutable": "Runner"}))
        with patch.object(store, "run") as runner:
            with self.assertRaisesRegex(ValueError, "Additional signed targets"):
                store.inspect_app(self.root, app, self.root)
            runner.assert_not_called()

    def test_config_archive_and_export_failures_propagate_without_verification(self):
        # Real subprocess error propagation is exercised at each command boundary;
        # no mocked success is counted as a signed app or a native archive.
        for failing_call in (1, 2, 3, 4):
            self.options_check()
            output = self.root / str(failing_call)
            with self.subTest(call=failing_call), patch.object(store, "inspect_archive") as inspect:
                calls = []
                def runner(command, **kwargs):
                    calls.append(command)
                    if len(calls) == failing_call:
                        raise subprocess.CalledProcessError(17, command)
                with patch.object(store, "run", side_effect=runner), patch.object(store, "inspect_export") as exported:
                    with self.assertRaises(subprocess.CalledProcessError):
                        store.build(self.root, output, self.path, "ABCDE12345", self.fingerprint, False)
                    exported.assert_not_called()
                    self.assertEqual(len(calls), failing_call)
                    if failing_call <= 3:
                        inspect.assert_not_called()

    def app_fixture(self, app):
        app.mkdir(parents=True)
        (app / "Info.plist").write_bytes(plistlib.dumps({
            "CFBundleExecutable": "Runner", "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "4", "CFBundleIdentifier": store.BUNDLE_ID,
            "DTSDKName": "iphoneos26.5", "DTXcode": "2660"}))
        (app / "Runner").write_bytes(b"\xcf\xfa\xed\xfe")
        (app / "Runner").chmod(0o755)
        framework = app / "Frameworks/tim2tox_ffi.framework"
        framework.mkdir(parents=True)
        (framework / "tim2tox_ffi").write_bytes(b"fixture, not a Mach-O")
        (framework / "PrivacyInfo.xcprivacy").write_bytes(plistlib.dumps({}))
        return framework

    def app_runner(self, command, **kwargs):
        result = subprocess.CompletedProcess(command, 0, stdout="", stderr="")
        if "release_version.sh" in command[1]:
            result.stdout = "4\n" if "--build-number" in command else "1.2.3\n"
        elif "native_payload.py" in command[1]:
            result.stdout = '[{"fixture": "command dispatch only; no native validation claimed"}]'
        return result

    def test_native_metadata_and_ffi_hook_gates_are_used_for_each_app(self):
        app = self.root / "Runner.app"
        framework = self.app_fixture(app)
        output = self.root / "evidence"
        with patch.object(store, "run", side_effect=self.app_runner) as runner:
            store.inspect_app(self.root, app, output)
        self.assertTrue((output / "native-inventory.json").is_file())
        commands = [call.args[0] for call in runner.call_args_list]
        self.assertTrue(any("--arch" in cmd and "arm64" in cmd for cmd in commands))
        self.assertTrue(any(str(self.root / "apps/ditmesh/ios/Runner/Info.plist") in cmd for cmd in commands))
        self.assertIn(["bash", str(self.root / "tool/ci/assert_no_test_hooks.sh"), str(framework)], commands)

    def test_wrong_version_and_missing_ffi_manifest_fail_closed(self):
        app = self.root / "Runner.app"
        framework = self.app_fixture(app)
        (framework / "PrivacyInfo.xcprivacy").unlink()
        with patch.object(store, "run", side_effect=self.app_runner):
            with self.assertRaisesRegex(ValueError, "framework privacy manifest"):
                store.inspect_app(self.root, app, self.root / "missing")
        info = plistlib.loads((app / "Info.plist").read_bytes())
        info["CFBundleShortVersionString"] = "9.9.9"
        (app / "Info.plist").write_bytes(plistlib.dumps(info))
        with patch.object(store, "run", side_effect=self.app_runner):
            with self.assertRaisesRegex(ValueError, "version does not match"):
                store.inspect_app(self.root, app, self.root / "version")

    def test_archive_rejects_missing_and_mismatched_main_symbols(self):
        app = self.root / "Runner.xcarchive/Products/Applications/Runner.app"
        self.app_fixture(app)
        (self.root / "archive-evidence").mkdir()
        with patch.object(store, "inspect_app"):
            with self.assertRaisesRegex(ValueError, "missing its main executable dSYM"):
                store.inspect_archive(self.root, self.root)
            dsym = self.root / "Runner.xcarchive/dSYMs/Runner.app.dSYM/Contents/Resources/DWARF/Runner"
            dsym.parent.mkdir(parents=True)
            dsym.write_bytes(b"fixture, not symbols")
            with patch.object(store, "symbol_uuids", side_effect=[{"arm64": "A"}, {"arm64": "B"}]):
                with self.assertRaisesRegex(ValueError, "UUIDs differ"):
                    store.inspect_archive(self.root, self.root)
            with patch.object(store, "symbol_uuids", return_value={"arm64": "A"}):
                store.inspect_archive(self.root, self.root)
        self.assertTrue((self.root / "archive-evidence/symbols.json").is_file())

    def test_archive_checks_actual_built_toolchain_before_commands(self):
        app = self.root / "Runner.xcarchive/Products/Applications/Runner.app"
        self.app_fixture(app)
        info_path = app / "Info.plist"
        info = plistlib.loads(info_path.read_bytes())
        info.update(DTSDKName="iphoneos18.5", DTXcode="1640")
        info_path.write_bytes(plistlib.dumps(info))
        with patch.object(store, "run") as runner:
            with self.assertRaisesRegex(ValueError, "iOS 26.*Xcode 26"):
                store.inspect_archive(self.root, self.root)
            runner.assert_not_called()

    def test_export_checks_actual_ipa_toolchain_before_signature_or_distribution_report(self):
        (self.root / "ipa").mkdir()
        (self.root / "ipa/App.ipa").write_bytes(b"fixture, not an exported application")
        def runner(command, **kwargs):
            self.assertEqual(command[0], "ditto")
            app = Path(command[-1]) / "Payload/Runner.app"
            self.app_fixture(app)
            info_path = app / "Info.plist"
            info = plistlib.loads(info_path.read_bytes())
            info["DTXcode"] = "1640"
            info_path.write_bytes(plistlib.dumps(info))
        with patch.object(store, "run", side_effect=runner) as invoked:
            with self.assertRaisesRegex(ValueError, "iOS 26.*Xcode 26"):
                store.inspect_export(self.root, self.root, "ABCDE12345", self.fingerprint, "fixture")
            self.assertEqual(invoked.call_count, 1)
        self.assertFalse((self.root / "export-evidence/distribution.json").exists())

    def test_archive_rejects_external_app_ancestor_framework_and_symbols_links(self):
        for linked_path in ("Products/Applications/Runner.app", "Products/Applications",
                            "Products/Applications/Runner.app/Frameworks/tim2tox_ffi.framework",
                            "dSYMs/Runner.app.dSYM/Contents/Resources/DWARF/Runner"):
            with self.subTest(linked_path=linked_path):
                output = self.root / str(len(list(self.root.iterdir())))
                archive = output / "Runner.xcarchive"
                link = archive / linked_path
                link.parent.mkdir(parents=True)
                external = self.root / ("external-" + output.name)
                is_directory = not linked_path.endswith("/DWARF/Runner")
                if is_directory:
                    external.mkdir()
                else:
                    external.write_bytes(b"symbols outside the archive")
                # Relative links may still escape the archive; no external
                # target bytes may be treated as a portable tar artifact.
                link.symlink_to(os.path.relpath(external, link.parent), target_is_directory=is_directory)
                with patch.object(store, "inspect_app") as inspected:
                    with self.assertRaisesRegex(ValueError, "symlinks"):
                        store.inspect_archive(self.root, output)
                    inspected.assert_not_called()

    def test_archive_rejects_symlink_root_absolute_and_dangling_links(self):
        external = self.root / "external"
        external.mkdir()
        root_link = self.root / "root-link"
        root_link.mkdir()
        (root_link / "Runner.xcarchive").symlink_to(external, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "real directory"):
            store.inspect_archive(self.root, root_link)
        for target in ("missing-target", str(external)):
            with self.subTest(target=target):
                output = self.root / ("dangling" if target == "missing-target" else "absolute")
                archive = output / "Runner.xcarchive"
                archive.mkdir(parents=True)
                (archive / "link").symlink_to(target)
                with self.assertRaises((ValueError, FileNotFoundError)):
                    store.inspect_archive(self.root, output)
        output = self.root / "absolute-internal"
        archive = output / "Runner.xcarchive"
        archive.mkdir(parents=True)
        (archive / "bytes").write_bytes(b"absolute targets are not relocatable")
        (archive / "link").symlink_to(archive / "bytes")
        with self.assertRaisesRegex(ValueError, "symlinks"):
            store.inspect_archive(self.root, output)

    def test_archive_preserves_internal_relative_framework_links(self):
        app = self.root / "Runner.xcarchive/Products/Applications/Runner.app"
        framework = self.app_fixture(app)
        (framework / "Versions/A").mkdir(parents=True)
        (framework / "Versions/A/resource").write_bytes(b"retained within the archive")
        (framework / "resource").symlink_to("Versions/A/resource")
        dsym = self.root / "Runner.xcarchive/dSYMs/Runner.app.dSYM/Contents/Resources/DWARF/Runner"
        dsym.parent.mkdir(parents=True)
        dsym.write_bytes(b"fixture, not symbols")
        (self.root / "archive-evidence").mkdir()
        with patch.object(store, "inspect_app"), patch.object(store, "symbol_uuids", return_value={"arm64": "A"}):
            store.inspect_archive(self.root, self.root)
        self.assertTrue((framework / "resource").is_symlink())
        self.assertTrue((self.root / "archive-evidence/symbols.json").is_file())

    def test_symbol_parser_rejects_simulator_or_empty_uuid_output(self):
        for output in ("", "UUID: 00000000-0000-0000-0000-000000000000 (x86_64) fixture"):
            with self.subTest(output=output), patch.object(store, "run", return_value=
                    subprocess.CompletedProcess([], 0, stdout=output)):
                with self.assertRaisesRegex(ValueError, "arm64 device slice"):
                    store.symbol_uuids(self.root)

    def test_invalid_profile_or_entitlement_types_fail_closed(self):
        for profile, entitlements in (([], {}), ({}, []), ({"Entitlements": []}, {})):
            if isinstance(profile, dict) and "Entitlements" in profile:
                profile = {**self.profile(), **profile}
            with self.subTest(profile=profile), self.assertRaises(ValueError):
                store.profile_evidence(profile, entitlements, "ABCDE12345", self.fingerprint)

    def test_bundle_executable_must_be_present_contained_native_file(self):
        app = self.root / "Runner.app"
        self.app_fixture(app)
        (app / "Directory").mkdir()
        (self.root / "Outside").write_bytes(b"\xcf\xfa\xed\xfe")
        (self.root / "Outside").chmod(0o755)
        (app / "Link").symlink_to(self.root / "Outside")
        (app / "Text").write_bytes(b"not a native executable")
        (app / "Text").chmod(0o755)
        for entry in ("", ".", "..", "MissingRunner", "Directory", "Link", "Text"):
            (app / "Info.plist").write_bytes(plistlib.dumps({"CFBundleExecutable": entry}))
            with self.subTest(entry=entry), patch.object(store, "run") as runner:
                with self.assertRaisesRegex(ValueError, "executable"):
                    store.inspect_app(self.root, app, self.root)
                runner.assert_not_called()

    def test_archive_rejects_unreviewed_sibling_application(self):
        applications = self.root / "Runner.xcarchive/Products/Applications"
        (applications / "Runner.app").mkdir(parents=True)
        (applications / "Other.app").mkdir()
        with patch.object(store, "inspect_app") as inspect:
            with self.assertRaisesRegex(ValueError, "exactly one"):
                store.inspect_archive(self.root, self.root)
            inspect.assert_not_called()


if __name__ == "__main__":
    unittest.main()
