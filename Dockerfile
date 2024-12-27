FROM elixir:alpine

RUN apk add --no-cache shadow
RUN apk update && apk add inotify-tools
RUN apk add nano
RUN apk add --update alpine-sdk
RUN mkdir /app
WORKDIR /app
COPY . .
RUN mix do deps.get, deps.compile
EXPOSE 4000
CMD ["mix", "phx.server"]