FROM cm2network/steamcmd as builder

ARG VERSION=stable

RUN ./steamcmd.sh \
      +@ShutdownOnFailedCommand 1 \
      +@NoPromptForPassword 1 \
      +login anonymous \
      +force_install_dir /home/steam/server \
      +app_update 294420 -beta "${VERSION}" validate \
      +quit

FROM debian:buster-slim

COPY --from=builder /home/steam/server /server

RUN apt-get update \
 && apt-get install -y --no-install-recommends --no-install-suggests telnet \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /etc/7d2d/{data,save}

COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
