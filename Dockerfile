FROM debian:13-slim

# Add PhasecoreX user-entrypoint script
ADD https://raw.githubusercontent.com/PhasecoreX/docker-user-image/master/user-entrypoint.sh /bin/user-entrypoint
RUN chmod +rx /bin/user-entrypoint && /bin/user-entrypoint --init
ENTRYPOINT ["/bin/user-entrypoint"]

# Install dependencies to run the server
RUN set -eux; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        # Updater
        ca-certificates \
        curl \
        zstd \
        # Server
        libc6:i386 \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    curl -SL -o ./libstdc++5_3.3.6-34_i386.deb http://ftp.debian.org/debian/pool/main/g/gcc-3.3/libstdc++5_3.3.6-34_i386.deb; \
    dpkg -i libstdc++5_3.3.6-34_i386.deb; \
    rm libstdc++5_3.3.6-34_i386.deb;

# Add local files
COPY root/ /

# Ports are as follows:
# 7777  UDP/IP  (Game Port)
# 7778  UDP/IP  (Query Port; game port + 1)
# 7787  UDP/IP  (GameSpy Query Port; game port + 10)
EXPOSE 7777/udp 7778/udp 7787/udp

CMD ["/app/start_server.sh"]
