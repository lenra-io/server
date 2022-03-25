FROM elixir:1.12-alpine AS build

ARG CI
ARG GH_PERSONNAL_TOKEN

ENV ALLOWED_CLIENT_ORIGINS='http://localhost:8080'

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
RUN mix do deps.get \
 || [[ "${CI}" == "true" ]] \
 && cd deps/application_runner \
 && git config submodule."priv/components-api".url "https://shiipou:${GH_PERSONNAL_TOKEN}@github.com/lenra-io/components-api.git" \
 && cd ../.. \
 && mix do deps.get

RUN mix do deps.compile --force

# build assets
RUN mix phx.digest

# compile and build release
RUN mix do compile, release lenra

# prepare release image
FROM erlang:24-alpine

RUN adduser -D lenra

USER lenra

WORKDIR /app

COPY --from=build --chown=lenra /app/_build/prod/rel/lenra .

ENTRYPOINT [ "bin/lenra" ]
CMD ["start"]
