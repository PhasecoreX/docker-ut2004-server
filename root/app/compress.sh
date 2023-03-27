#!/usr/bin/env bash
set -eu

compress_dir=$1
compress_ext="uz2"

# Exit if no target directory was passed in
if [ -z "${compress_dir:-}" ]; then
    exit 0
fi

echo "Checking for new files to compress..."

if [ ! -d "${compress_dir}" ]; then
    echo "Destination directory does not exist: ${compress_dir}"
    exit 1
fi

# Find all source file directories
compressed_files=()
for directory in /data/{addons,server}/{Animations,Maps,Music,Sounds,StaticMeshes,System,Textures}; do
    if [ ! -d "${directory}" ]; then
        continue
    fi

    # Determine file extension we want to compress in this directory
    case "${directory}" in
        */Animations)
            extension="ukx"
        ;;
        */Maps)
            extension="ut2"
        ;;
        */Music)
            extension="ogg"
        ;;
        */Sounds)
            extension="uax"
        ;;
        */StaticMeshes)
            extension="usx"
        ;;
        */System)
            extension="u"
        ;;
        */Textures)
            extension="utx"
        ;;
        *)
            echo "Don't know how to handle ${directory}"
            continue
        ;;
    esac

    # Find all files to compress
    readarray -d '' files < <(find "${directory}" -iname "*.${extension}" -type f -print0)
    for sourcepath in "${files[@]}"; do

        # Get source date and filename without directory, make sure we haven't already compressed it
        filename=$(basename "${sourcepath}")
        sourcedate=$(stat -c %Y "${sourcepath}")
        if echo "${compressed_files[@]}" | grep -q -F --word-regexp "${filename}"; then
            continue
        fi
        compressed_files+=("${filename}")
        destination="${compress_dir}/${filename}.${compress_ext}"

        # Skip compression if compressed file already exists and timestamp matches the source
        if [ -f "${destination}" ]; then
            destinationdate=$(stat -c %Y "${destination}")
            if [ "${sourcedate}" -eq "${destinationdate}" ]; then
                # echo "Already compressed ${sourcepath}"
                continue
            fi
        fi

        echo "Compressing ${sourcepath}..."
        set +e
        ./ucc-bin compress "${sourcepath}" -nohomedir
        set -e
        if [ -f "${sourcepath}.${compress_ext}" ]; then
            # Move compressed file to destination, make it readable, update modification date
            mv -f "${sourcepath}.${compress_ext}" "${destination}"
            chmod +r "${destination}"
            touch -d "@${sourcedate}" "${destination}"
            # When ucc-bin compresses a file, it does all that match case insensitive. Delete the extras.
            find "${directory}" -iname "${filename}.${compress_ext}" -type f -delete
        else
            echo "Failed to compress ${sourcepath}"
        fi
    done
done
