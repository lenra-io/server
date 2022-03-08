# This is the prod config, loaded on compile time during CI/CD. This is used for staging/test and prod environments.
# There is NO important data here, all secret/passwords and dynamic config are stored in releases.exs

import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :lenra_web, LenraWeb.Endpoint,
  http: [
    transport_options: [socket_opts: [:inet6]]
  ],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :lenra,
  faas_secrets: ["gitlab-registry"]
