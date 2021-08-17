FROM elixir:1.12-alpine AS build

ARG CI
ARG CI_JOB_TOKEN

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
RUN mix do deps.get, deps.compile

# build assets
RUN mix phx.digest

# compile and build release
RUN mix do compile, release lenra

# prepare release image
FROM erlang:24-alpine

WORKDIR /app
COPY --from=build /app/_build/prod/rel/lenra .

RUN adduser -D lenra && chown -R lenra:lenra .
USER lenra

ENTRYPOINT [ "bin/lenra" ]
CMD ["start"]