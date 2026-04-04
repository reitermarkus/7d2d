FROM docker.io/cm2network/steamcmd:root@sha256:e6b6b3503bf0e41feafe12dc709c90151afba193e1292cac55d28a7d470b1493

RUN apt-get update \
  && apt-get install --no-install-recommends -y tcl-expect=5.45.4-4 inetutils-telnet=2:2.6-3+deb13u3 \
  && rm -rf /var/lib/apt/lists/*

ENV DATA_DIR=/data
ENV SERVER_DIR=/server
RUN mkdir -p "${DATA_DIR}" "${SERVER_DIR}" \
  && chown -R "${USER}:${USER}" "${DATA_DIR}" "${SERVER_DIR}"

USER ${USER}

COPY graceful-shutdown.exp /graceful-shutdown.exp
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
