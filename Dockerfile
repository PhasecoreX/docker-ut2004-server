FROM phasecorex/user-debian:10-slim as server

# Install dependencies to run the server
RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends  \
        # Updater
        ca-certificates \
        curl \
        xz-utils \
        # Server
        lib32gcc1 \
        libstdc++5:i386 \
        libstdc++6:i386 \
        libsdl1.2debian \
    ; \    
    rm -rf /var/lib/apt/lists/*

# Add local files
COPY root/ /

# Ports are as follows:
# 7777  UDP/IP  (Game Port)
# 7778  UDP/IP  (Query Port; game port + 1)
# 7787  UDP/IP  (GameSpy Query Port; game port + 10)
EXPOSE 7777/udp 7778/udp 7787/udp

CMD ["/bin/sh", "/app/start_server.sh"]

LABEL maintainer="Ryan Foster <phasecorex@gmail.com>"
