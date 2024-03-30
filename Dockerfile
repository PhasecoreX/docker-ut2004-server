FROM debian:12-slim

# Add PhasecoreX user-entrypoint script
ADD https://raw.githubusercontent.com/PhasecoreX/docker-user-image/master/user-entrypoint.sh /bin/user-entrypoint
RUN chmod +x /bin/user-entrypoint && /bin/user-entrypoint --init
ENTRYPOINT ["/bin/user-entrypoint"]

# Install dependencies to run the server
RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends  \
        # Updater
        ca-certificates \
        curl \
        zstd \
        # Server
        lib32gcc-s1 \
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

CMD ["/app/start_server.sh"]
