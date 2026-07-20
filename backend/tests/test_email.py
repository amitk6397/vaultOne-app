import unittest
from unittest.mock import patch

from fastapi import HTTPException

from src.core.email import send_otp_email


class EmailDeliveryTests(unittest.TestCase):
    def test_debug_mode_allows_response_otp_when_brevo_rejects_email(self):
        provider_error = HTTPException(status_code=502, detail="provider rejected")

        with patch(
            "src.core.email._send_with_brevo",
            side_effect=provider_error,
        ):
            send_otp_email(
                to_email="test@example.com",
                otp="123456",
                purpose="register",
            )


if __name__ == "__main__":
    unittest.main()
