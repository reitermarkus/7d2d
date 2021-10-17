FROM cm2network/steamcmd:root

RUN apt-get update \
 && apt-get install -y expect telnet \
 && rm -rf /var/lib/apt/lists/*

USER ${USER}

COPY graceful-shutdown.exp /graceful-shutdown
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
