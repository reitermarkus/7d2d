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
COPY entrypoint.sh /server/entrypoint.sh
CMD ["/server/entrypoint.sh"]
