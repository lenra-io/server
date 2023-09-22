# This is the prod config, loaded on compile time during CI/CD. This is used for staging/test and prod environments.
# There is NO important data here, all secret/passwords and dynamic config are stored in releases.exs

import Config

config :identity_web, IdentityWeb.Endpoint,
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :lenra_web, LenraWeb.Endpoint,
  http: [
    transport_options: [socket_opts: [:inet6]]
  ],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :lenra,
  faas_secrets: ["gitlab-registry"],
  stripe_secret: System.get_env("STRIPE_SECRET")
