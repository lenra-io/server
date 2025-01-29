FROM elixir:1.14-alpine AS build

# prepare build dir
WORKDIR /app

# install build dependencies
RUN apk add --no-cache build-base git python3 openssh

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# copy needed files
COPY . .

# install mix dependencies
# Change token for application_runner/component-api submodule
RUN mix do deps.get

RUN mix do deps.compile --force

# build assets
RUN mix phx.digest

# compile and build release
RUN mix compile
RUN mix esbuild default --minify
RUN mix release lenra

# prepare release image
FROM erlang:24-alpine

RUN adduser -D lenra

USER lenra

WORKDIR /app

COPY --chmod=777 entrypoint.sh /entrypoint.sh

COPY --from=build --chown=lenra /app/_build/prod/rel/lenra .

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["start"]
