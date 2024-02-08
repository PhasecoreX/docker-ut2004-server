#!/usr/bin/env sh
set -euf

download_install() {
    set -e
    url=$1
    md5=$2
    filename=$3

    download_path="${version_directory}/${filename}"

    # If the user knows what they're doing, skip all downloads
    if [ "${SKIP_INSTALL:-}" = "true" ]; then
        return
    fi

    # If this pack is up to date, skip downloading it
    if [ "${force_update}" = 0 ] && [ -f "${download_path}.txt" ] && [ "$(cat "${download_path}.txt")" = "${md5}" ]; then
        base_pack_installed=1
        return
    fi

    # If we are updating this pack, all packs after it must also be updated
    force_update=1
    rm -f "${download_path}.txt"

    # If this is the first pack to be installed, delete the entire server folder
    if [ "${base_pack_installed}" = 0 ]; then
        rm -rf "${server_directory}"
    fi

    echo "Downloading ${filename} archive..."
    mkdir -p "${version_directory}"
    if [ -z "${url##*'google.com'*}" ]; then
        download_url="https://drive.usercontent.google.com/download"
        # Get the "this file is really big" banner page:
        curl -#SL -c "${version_directory}/cookies.txt" "${url}" -o "${version_directory}/confirm.html"

        # Extract all confirmation parameters:
        confirm="$(pup 'form#download-form > input[name=confirm] attr{value}' < "${version_directory}/confirm.html")"
        uuid="$(pup 'form#download-form > input[name=uuid] attr{value}' < "${version_directory}/confirm.html")"
        fileid="$(pup 'form#download-form > input[name=id] attr{value}' < "${version_directory}/confirm.html")"

        # Prepare the "final" download URL and download the archive:
        finalurl="${download_url}?id=${fileid}&export=download&confirm=${confirm}&uuid=${uuid}"
        curl -#SL -b "${version_directory}/cookies.txt" -o "${download_path}" "${finalurl}"

        # Clean up the cookies and confirmation page:
        rm -f "${version_directory}/confirm.html" "${version_directory}/cookies.txt"
    else
        curl -#SL "${url}" -o "${download_path}"
    fi

    echo "Verifying md5 checksum ${md5}"
    echo "${md5} ${download_path}" | md5sum -c -

    echo "Extracting ${filename} archive..."
    mkdir -p "${server_directory}"
    tar -xf "${download_path}" -C "${server_directory}"

    echo "Removing ${filename} archive"
    rm "${download_path}"

    mkdir -p "${version_directory}"
    echo "${md5}" >"${download_path}.txt"
    base_pack_installed=1
}

server_directory="$1"
version_directory="${server_directory}/.versions"

force_update=0
base_pack_installed=0

# Update to new md5 (same files but compressed better)
if [ -f "${version_directory}/ut2004server_base.txt" ] && [ "$(cat "${version_directory}/ut2004server_base.txt")" = "561a9e3a5df492c2246c0be002eaf76e" ]; then
    echo "5f9c999ed8f695a67877018ba6a12607" >"${version_directory}/ut2004server_base.txt"
fi

# Install base server with latest patch (3369.2), Epic ECE Bonus Pack, and Bonus Megapack
download_install \
    "https://drive.google.com/uc?export=download&id=1yK3QcsE0s-F5weMy-7ACUs-b9VS1AYD_" \
    5f9c999ed8f695a67877018ba6a12607 \
    ut2004server_base
