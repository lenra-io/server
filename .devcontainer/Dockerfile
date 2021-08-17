FROM elixir:1.11-alpine

# ** [Optional] Uncomment this section to install additional packages. **
#
RUN apk add --no-cache build-base git python3

RUN mix local.hex --force && \
    mix local.rebar --force
RUN mix archive.install hex phx_new 1.5.4 --force
