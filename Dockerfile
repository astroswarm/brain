FROM elixir:1.4-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez

RUN mkdir -p /app
WORKDIR /app
ADD ./ /app

ENV PORT 8080
ENV MIX_ENV prod
RUN mix do deps.get, compile, phoenix.digest

EXPOSE 8080

CMD ["mix", "phoenix.server"]