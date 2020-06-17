#!/usr/bin/env sh
set -euf

download_install() {
    set -e
    url=$1
    md5=$2
    filename=$3

    # If the user knows what they're doing, skip all downloads
    if [ "${SKIP_INSTALL:-}" = "true" ]; then
        return
    fi

    # If this pack is up to date, skip downloading it
    if [ -f "/data/server/.versions/${filename}.txt" ] && [ "$(cat "/data/server/.versions/${filename}.txt")" = "${md5}" ]; then
        return
    fi

    # Exit if the user hasn't agreed to downloading anything
    if [ "${DOWNLOAD_DATA:-}" != "true" ]; then
        echo ""
        echo "Server files need to be downloaded/updated. This will be a ~750MB download." >&2
        echo "If you agree to this, set the environment variable DOWNLOAD_DATA=true" >&2
        echo "You can also set SKIP_INSTALL=true if you want to skip downloading/updating entirely." >&2
        exit 1
    fi

    echo "Downloading ${filename} archive..."
    if [ -z "${url##*'google.com'*}" ]; then
        curl -#SL -c cookies.txt "${url}" | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p' >confirm.txt
        curl -#SL -b cookies.txt -o "${filename}" "${url}&confirm=$(cat confirm.txt)"
        rm -f confirm.txt cookies.txt
    else
        curl -#SL "${url}" -o "${filename}"
    fi

    echo "Verifying md5 checksum ${md5}"
    echo "${md5} ${filename}" | md5sum -c -

    echo "Extracting ${filename} archive..."
    tar -xf "${filename}" -C "/data/server"

    echo "Removing ${filename} archive"
    rm "${filename}"

    mkdir -p "/data/server/.versions"
    echo "${md5}" >"/data/server/.versions/${filename}.txt"
}

# Install base server with latest patch (3369.2), Epic ECE Bonus Pack, and Bonus Megapack
download_install \
    "https://drive.google.com/uc?export=download&id=1TFNheF20mPGSGxbhdVmfRi5ZQSdK2RS_" \
    561a9e3a5df492c2246c0be002eaf76e \
    ut2004server_base
