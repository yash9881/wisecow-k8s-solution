FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    SRVPORT=4499 \
    PATH="/usr/games:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      cowsay \
      fortune-mod \
      netcat-openbsd \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY wisecow.sh /app/wisecow.sh

RUN chmod +x /app/wisecow.sh \
    && useradd --system --uid 10001 --create-home wisecow \
    && chown -R wisecow:wisecow /app

USER wisecow
EXPOSE 4499

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD nc -z 127.0.0.1 "$SRVPORT" || exit 1

CMD ["/app/wisecow.sh"]
