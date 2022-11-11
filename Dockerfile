# https://hub.docker.com/r/hexpm/elixir/tags
FROM hexpm/elixir:1.13.4-erlang-24.1.2-alpine-3.14.2 AS build
ENV MIX_ENV=prod

WORKDIR /app

RUN apk add --no-cache build-base npm git automake autoconf libtool gmp-dev

RUN mix local.rebar --force \
    && mix local.hex --force

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
COPY lib lib
RUN mix do compile, release

FROM alpine:3.9 AS app
RUN apk add --update --no-cache automake autoconf libtool gmp-dev

WORKDIR /opt/app

ENV MIX_ENV=prod PORT=80 HOME=/app PHX_SERVER=true

EXPOSE 80

COPY --from=build /app/_build/prod/rel/paymail ./

CMD ["sh", "-c", "bin/paymail start"]