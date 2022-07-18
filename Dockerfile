FROM cm2network/steamcmd:root

RUN apt-get update \
 && apt-get install --no-install-recommends -y expect=~5.45 telnet=~0.17 \
 && rm -rf /var/lib/apt/lists/*

ENV DATA_DIR=/data
ENV SERVER_DIR=/server
RUN mkdir -p "${DATA_DIR}" "${SERVER_DIR}" \
 && chown -R "${USER}:${USER}" "${DATA_DIR}" "${SERVER_DIR}"

USER ${USER}

COPY graceful-shutdown.exp /graceful-shutdown
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
