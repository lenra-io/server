# Database management

Lenra use two databases:

- A PostgreSQL database for the main data of the Lenra platform
- A MongoDB database for the applications data

A third one can be added for the OAuth2 server.

## PostgreSQL

The PostgreSQL database is managed by Ecto, the database wrapper for Elixir.

### Migrations

The migrations are located in two different directories:

- `libs/application_runner/priv/repo/migrations`: the migrations for the core of the Lenra app system. Those are common to the Lenra platform and the devtool.
- `apps/lenra/priv/repo/migrations`: the migrations for the Lenra platform

To create a new migration for the Lenra platform, you can use the following command:

```bash
mix ecto.gen.migration <migration_name>
```

To run the migrations, you can use the following command which is included in the `mix setup` command:

```bash
mix ecto.migrate
```
