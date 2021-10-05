FROM steamcmd/steamcmd:latest

RUN apt-get update \
 && apt-get install -y expect telnet \
 && rm -rf /var/lib/apt/lists/*

COPY graceful-shutdown.exp /graceful-shutdown
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
