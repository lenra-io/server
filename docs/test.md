# Local testing

To test the Lenra server locally...

## Start the dependency tools

```bash
docker compose up -d
```

## Initiate the database

```bash
mix setup
```

If you want to reset the database, you can run the following command:

```bash
mix ecto.reset
```

## Add an app in database

First, you need to add an app in the database. You can do this by running the following command:

```bash
./scripts/create_test_app.sh
```

## Run the server

```bash
FAAS_URL="http://localhost:3000" mix phx.server
```