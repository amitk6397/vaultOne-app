# vaultOne Backend

FastAPI backend scaffold with user/admin module separation and MySQL-ready database configuration.

## Run locally

```powershell
cd backend
.\venv\Scripts\activate
pip install -r requirements.txt
uvicorn src.main:app --reload
```

API docs:

```text
http://127.0.0.1:8000/docs
```

## Auth endpoints

```text
POST /api/v1/user/auth/register
POST /api/v1/user/auth/login
POST /api/v1/user/auth/forgot-password
POST /api/v1/user/auth/verify-otp
POST /api/v1/user/auth/reset-password
POST /api/v1/user/auth/resend-otp
POST /api/v1/admin/auth/login
GET /api/v1/admin/users
PATCH /api/v1/admin/users/{user_id}/block
PATCH /api/v1/admin/users/{user_id}/unblock
```

## Create admin

Do not hardcode admin credentials in source code. Create the first admin from the
backend folder:

```powershell
python -m src.admin.create_admin --email admin@vaultone.app --full-name "VaultOne Admin"
```

For local testing only, you can pass a password directly:

```powershell
python -m src.admin.create_admin --email admin@vaultone.app --full-name "VaultOne Admin" --password "Admin@12345"
```

## Content endpoints

Admin can create, read, edit, and delete onboarding and policy content:

```text
POST /api/v1/admin/onboarding
GET /api/v1/admin/onboarding
GET /api/v1/admin/onboarding/{slide_id}
PUT /api/v1/admin/onboarding/{slide_id}
DELETE /api/v1/admin/onboarding/{slide_id}

POST /api/v1/admin/policies
GET /api/v1/admin/policies
GET /api/v1/admin/policies/{policy_id}
PUT /api/v1/admin/policies/{policy_id}
DELETE /api/v1/admin/policies/{policy_id}
```

Users can only read active content:

```text
GET /api/v1/user/onboarding
GET /api/v1/user/policies/privacy
GET /api/v1/user/policies/terms-and-conditions
GET /api/v1/user/policies/{policy_type}
```

Add real MySQL credentials in `.env` before connecting to the database.
