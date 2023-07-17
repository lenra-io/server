How to test it : 
- Start dependancies (Hydra + Db) `docker-compose up -d`
- Start server `mix phx.server`
- Create the Hydra client using the CLI :

    ```bash
    > docker-compose exec hydra hydra create client --endpoint http://127.0.0.1:4445 --token-endpoint-auth-method none --scope foo --redirect-uri https://oauthdebugger.com/debug
    CLIENT ID       <random_uuid>
    CLIENT SECRET
    GRANT TYPES     authorization_code
    RESPONSE TYPES  code
    SCOPE           foo
    AUDIENCE
    REDIRECT URIS   https://oauthdebugger.com/debug
    ```
- Go to https://oauthdebugger.com
  - Authorize URI : http://localhost:4444/oauth2/auth
  - Client ID : the one above
  - scope : foo
    - [x] Use PKCE?
  - Token URI : http://localhost:4444/oauth2/token
  - Send Request ! 
