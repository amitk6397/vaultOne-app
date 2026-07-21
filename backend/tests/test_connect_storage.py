import unittest
from unittest.mock import patch

from src.user.connect.storage import signed_private_download_url


class SignedPrivateDownloadUrlTests(unittest.TestCase):
    @patch("src.user.connect.storage.cloudinary.utils.private_download_url")
    def test_raw_asset_format_is_signed_separately(self, private_url):
        private_url.return_value = "https://api.cloudinary.test/download"

        result = signed_private_download_url(
            "cloudinary:vaultone/connect/7/random-file.PNG",
            "holiday photo.PNG",
        )

        self.assertEqual(result, "https://api.cloudinary.test/download")
        args, kwargs = private_url.call_args
        self.assertEqual(args[:2], ("vaultone/connect/7/random-file", "png"))
        self.assertEqual(kwargs["resource_type"], "raw")
        self.assertEqual(kwargs["type"], "authenticated")
        self.assertEqual(kwargs["attachment"], "holiday photo.PNG")

    def test_cloud_asset_without_extension_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "missing its file format"):
            signed_private_download_url(
                "cloudinary:vaultone/connect/7/random-file",
                "file",
            )


if __name__ == "__main__":
    unittest.main()
