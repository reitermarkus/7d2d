FROM cm2network/steamcmd as builder

ARG VERSION=stable

COPY --chown=steam:steam entrypoint.sh /home/steam/server/entrypoint.sh

RUN ./steamcmd.sh \
      +@ShutdownOnFailedCommand 1 \
      +@NoPromptForPassword 1 \
      +login anonymous \
      +force_install_dir /home/steam/server \
      +app_update 294420 -beta "${VERSION}" validate \
      +quit

FROM debian:buster-slim

CMD ["/server/entrypoint.sh"]

COPY --from=builder /home/steam/server /server
