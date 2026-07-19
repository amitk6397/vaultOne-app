import tempfile
import unittest
from pathlib import Path

from pydantic import ValidationError

from src.core.security import create_access_token, decode_token
from src.user.connect.dtos import ContactDiscoverRequest, DisappearingMessagesRequest
from src.user.connect.service import safe_filename, sha256_file, verify_magic
from src.user.connect.storage import is_cloud_key, local_relative_key


class VaultConnectContractTests(unittest.TestCase):
    def test_contacts_require_e164(self):
        self.assertEqual(ContactDiscoverRequest(phones=["+919876543210"]).phones, ["+919876543210"])
        with self.assertRaises(ValidationError):
            ContactDiscoverRequest(phones=["9876543210"])

    def test_contact_batch_is_bounded_and_deduplicated(self):
        self.assertEqual(ContactDiscoverRequest(phones=["+919876543210", "+919876543210"]).phones, ["+919876543210"])
        with self.assertRaises(ValidationError):
            ContactDiscoverRequest(phones=["+919876543210"] * 501)

    def test_disappearing_options_are_allowlisted(self):
        self.assertEqual(DisappearingMessagesRequest(duration_seconds=86400).duration_seconds, 86400)
        with self.assertRaises(ValidationError):
            DisappearingMessagesRequest(duration_seconds=17)

    def test_filename_is_confined(self):
        self.assertEqual(safe_filename("../../secret.pdf"), "secret.pdf")

    def test_checksum_and_magic(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.pdf"
            path.write_bytes(b"%PDF-1.7\nsecure")
            self.assertTrue(verify_magic(path, "pdf"))
            self.assertEqual(len(sha256_file(path)), 64)

    def test_private_storage_key_types(self):
        self.assertTrue(is_cloud_key("cloudinary:vaultone/connect/object"))
        self.assertFalse(is_cloud_key("local:pending/object"))
        self.assertEqual(local_relative_key("local:pending/object"), "pending/object")

    def test_session_generation_is_carried_by_access_token(self):
        token = create_access_token(
            "42",
            claims={"role": "user", "session_version": 7},
        )
        claims = decode_token(token)
        self.assertEqual(claims["sub"], "42")
        self.assertEqual(claims["session_version"], 7)


if __name__ == "__main__":
    unittest.main()
