#!/usr/bin/env bash
set -e

# exit if there is no target directory
if [ -z ${COMPRESS_DIR+x} ]; then
  exit 0
fi

echo "Checking for files to compress..."

# create target directory, if needed
mkdir -p "${COMPRESS_DIR}"

# find all files to compress
files=()
# Server
if ls /data/server/Animations/*.ukx >/dev/null 2>&1; then
    files+=(/data/server/Animations/*.ukx)
fi
if ls /data/server/Maps/*.ut2 >/dev/null 2>&1; then
    files+=(/data/server/Maps/*.ut2)
fi
if ls /data/server/Music/*.ogg >/dev/null 2>&1; then
    files+=(/data/server/Music/*.ogg)
fi
if ls /data/server/Sounds/*.uax >/dev/null 2>&1; then
    files+=(/data/server/Sounds/*.uax)
fi
if ls /data/server/StaticMeshes/*.usx >/dev/null 2>&1; then
    files+=(/data/server/StaticMeshes/*.usx)
fi
if ls /data/server/System/*.u >/dev/null 2>&1; then
    files+=(/data/server/System/*.u)
fi
if ls /data/server/Textures/*.utx >/dev/null 2>&1; then
    files+=(/data/server/Textures/*.utx)
fi
# Addons
if ls /data/addons/Animations/*.ukx >/dev/null 2>&1; then
    files+=(/data/addons/Animations/*.ukx)
fi
if ls /data/addons/Maps/*.ut2 >/dev/null 2>&1; then
    files+=(/data/addons/Maps/*.ut2)
fi
if ls /data/addons/Music/*.ogg >/dev/null 2>&1; then
    files+=(/data/addons/Music/*.ogg)
fi
if ls /data/addons/Sounds/*.uax >/dev/null 2>&1; then
    files+=(/data/addons/Sounds/*.uax)
fi
if ls /data/addons/StaticMeshes/*.usx >/dev/null 2>&1; then
    files+=(/data/addons/StaticMeshes/*.usx)
fi
if ls /data/addons/System/*.u >/dev/null 2>&1; then
    files+=(/data/addons/System/*.u)
fi
if ls /data/addons/Textures/*.utx >/dev/null 2>&1; then
    files+=(/data/addons/Textures/*.utx)
fi

for sourcepath in "${files[@]}"; do
  filename=$(basename "${sourcepath}")          # get source filename without directory
  destination="${COMPRESS_DIR}/${filename}.uz2" # compressed file's path
  sourcedate=$(stat -c %Y "${sourcepath}")      # get source file's modification date

  # skip compression if compressed file already exists and timestamp matches the source
  if [ -e "${destination}" ]; then
    destinationdate=$(stat -c %Y "${destination}") # get compressed file's modification date
    if [ "${sourcedate}" -eq "${destinationdate}" ]; then
      # echo "already compressed ${sourcepath}"
      continue
    fi
  fi

  ./ucc-bin compress "${sourcepath}" -nohomedir # compress the source file
  mv -f "${sourcepath}.uz2" "${destination}"    # move compressed file to the destination
  chmod o+r "${destination}"                    # add read permission to compressed file
  touch -d "@${sourcedate}" "${destination}"    # change modification date of compressed file to match the source
done
