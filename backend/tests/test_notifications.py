import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

import firebase_admin

from src.core.notifications import (
    firebase_credentials_path,
    initialize_firebase,
)


class FirebaseNotificationTests(unittest.TestCase):
    def tearDown(self):
        try:
            firebase_admin.delete_app(firebase_admin.get_app())
        except ValueError:
            pass

    def test_relative_credentials_path_resolves_from_backend(self):
        with patch(
            "src.core.notifications.settings.firebase_credentials_path",
            "credentials.json",
        ):
            expected = Path(__file__).resolve().parents[1] / "credentials.json"
            self.assertEqual(firebase_credentials_path(), expected.resolve())

    def test_missing_credentials_raise_actionable_error(self):
        with patch(
            "src.core.notifications.settings.firebase_credentials_path",
            "missing-firebase-credentials.json",
        ):
            with self.assertRaisesRegex(
                RuntimeError,
                "FIREBASE_CREDENTIALS_PATH",
            ):
                initialize_firebase()

    def test_existing_firebase_app_is_reused(self):
        existing = MagicMock()
        with patch("src.core.notifications.firebase_admin.get_app", return_value=existing):
            self.assertIs(initialize_firebase(), existing)


if __name__ == "__main__":
    unittest.main()
