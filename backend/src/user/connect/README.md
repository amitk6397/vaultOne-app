# Vault Connect

Vault Connect is integrated under the existing `/api/v1` API and uses the existing user JWT. All entity IDs except existing user IDs are UUID strings.

## REST contracts

All JSON endpoints return the existing `{success, message, data}` envelope.

- `POST /contacts/discover`: `{phones: ["+919..."]}`; authenticated, 500 max, rate limited. Returns `data.matches`.
- `POST /conversations/direct`: `{user_id: 2}`; returns the only direct conversation for the pair.
- `GET /conversations?cursor=<uuid>&limit=30`: newest first cursor page.
- `GET /conversations/{id}`
- `GET /conversations/{id}/messages?cursor=<uuid>&limit=50`: newest first cursor page.
- `PATCH /conversations/{id}/disappearing-messages`: `{duration_seconds: 0|3600|86400|604800|2592000}`.
- `DELETE /conversations/{id}/clear`
- `POST /messages`: `{client_message_id, conversation_id, message_type, content?, reply_to_message_id?, attachment_ids: []}`.
- `POST /messages/{id}/delivered`, `POST /messages/{id}/read`
- `DELETE /messages/{id}?scope=me|everyone`
- `POST /attachments/init-upload`, then multipart `PUT /attachments/{id}/content`, then `POST /attachments/{id}/complete`.
- `POST /attachments/{id}/cancel`; `GET /attachments/{id}/download-url` returns a five-minute private URL.
- `GET /users/blocked`, `POST|DELETE /users/{id}/block`
- `POST /reports`

Completed uploads are authenticated Cloudinary `raw` assets by default. The database stores only the private provider object ID and download requests return five-minute signed URLs. Set `VAULT_CONNECT_STORAGE_BACKEND=local` only for development; local downloads remain membership-protected and tokenized. Permanent public provider URLs are never stored.

## WebSocket contract

Connect to `/api/v1/ws/vault-connect?token=<access JWT>`. Packets are `{event, data}`.

Client events: `message.send`, `message.delivered`, `message.read`, `typing.start`, `typing.stop`, `conversation.join`, `conversation.leave`.

Server events: `message.created`, `message.deleted`, `message.delivered`, `message.read`, `typing.started`, `typing.stopped`, `user.online`, `user.offline`, `user.blocked`, `conversation.updated`, `error`.

Every event authenticates the connection and re-checks conversation membership and block state before disclosing or mutating data. Reconnection uses REST cursor sync for missed messages.

## Operations

Run `migrations/20260717_vault_connect.sql` and then `migrations/20260718_user_token_states.sql` on an existing database. The application also registers the models with SQLAlchemy `create_all` for clean development databases. Session revocation increments a per-user JWT generation, invalidates access and refresh tokens, disables FCM device tokens, and closes live Vault Connect sockets.

The cleanup worker starts with FastAPI and runs every 15 minutes. Admins can also trigger `POST /admin/vault-connect/cleanup/run`.

Admin endpoints under `/admin/vault-connect` expose counts, storage totals, failed uploads, explicit report evidence, configuration, access controls and cleanup status. They never expose normal private conversation content or downloadable files.
