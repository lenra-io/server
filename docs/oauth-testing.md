# Oauth testing

## Test the Oauth protocol using Oauth Debugger
 
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


## Create the Oauth clients for backoffice client and apps client


Before starting the backoffice/app client, you shoud create a the Oauth clients first.
Make sure ORY Hydra is started : 
```
docker compose up -d
```

Then create both clients : 
```
mix create_oauth2_client backoffice
mix create_oauth2_client apps
```

Get the client_ids and put them in the client OAUTH_CLIENT_ID argument.
You're good to go !

### Create Lenra OAuth clients for the staging environment

```bash
/app/bin/lenra eval 'Mix.Tasks.CreateOauth2Client.run(["apps", "--redirect-uri", "https://app.staging.lenra.io/redirect.html", "--allowed-origin", "https://app.staging.lenra.io"])'
/app/bin/lenra eval 'Mix.Tasks.CreateOauth2Client.run(["backoffice", "--redirect-uri", "https://dev.staging.lenra.io/redirect.html", "--allowed-origin", "https://dev.staging.lenra.io"])'
```

#### Update the scopes of app OAuth client for the staging environment

Use the `Lenra.Apps.update_oauth2_client/1` function patch the app OAuth client for the staging environment.

```bash
# Updates the app OAuth client scopes for the staging environment
/app/bin/lenra eval 'Lenra.Apps.update_oauth2_client(%{"client_id" => "1bafc4d4-3759-4542-a751-82b6c96a29fc", "scopes" => ["profile", "store", "resources", "manage:account", "app:websocket"]})'
```

## Test external app clients

In order to test the OAuth for external apps, you must have an app in the Lenra database.

### Prerequisites

Create a Lenra app in the database :

- Create an OAuth client for the backoffice
    ```bash
    mix create_oauth2_client backoffice
    ```
- Start the backoffice Flutter app
- Create an app in the backoffice

### Create the external app OAuth client

Here is the full process to test the OAuth flow for an external app :
- Create an OAuth client for the app (here for the environment 1)
    ```bash
    mix create_oauth2_client custom --redirect-uri https://oauthdebugger.com/debug --scope app:websocket --environment-id 1
    ```
- Go to https://oauthdebugger.com
  - Authorize URI : http://localhost:4444/oauth2/auth
  - Redirect URI: https://oauthdebugger.com/debug
  - Client ID : the one abovemix create_oauth2_client backoffice
  - scope : app:websocket
    - [x] Use PKCE?
  - Token URI : http://localhost:4444/oauth2/token
  - Send Request !