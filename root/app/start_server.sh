#!/usr/bin/env sh
set -e

# Check if the user actually reads instructions
if [ $(stat -c "%d" /) -eq $(stat -c "%d" /data) ]; then
    echo "Try reading the instructions before running this image!"
    exit 1
fi

# Switch to the server System directory
mkdir -p /data/server/System
cd /data/server/System

# Download/update server files
/app/install.sh

# Make server executible
chmod +x ./ucc-bin

# Make addons directories if they don't exist
mkdir -p /data/addons/Animations
mkdir -p /data/addons/Maps
mkdir -p /data/addons/Music
mkdir -p /data/addons/Saves
mkdir -p /data/addons/Sounds
mkdir -p /data/addons/StaticMeshes
mkdir -p /data/addons/System
mkdir -p /data/addons/Textures
mkdir -p /data/config

# Move any .ini files and cdkey (not symlinked) in System directories into /data/config (no overwrite)
find /data/addons/System/ /data/server/System/ -type f \( -name '*.ini' -o -name 'cdkey' \) -exec mv -n -t /data/config {} +
rm -f /data/addons/System/*.ini /data/server/System/*.ini /data/server/System/cdkey
ln -s /data/config/* /data/server/System/

# Fix up (users) UT2004.ini to have /data/addons folders defined
if ! grep -Fxq "Paths=/data/addons/Saves/*.uvx" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/Saves/*.uvx' /data/config/UT2004.ini
fi
if ! grep -Fxq "Paths=/data/addons/Animations/*.ukx" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/Animations/*.ukx' /data/config/UT2004.ini
fi
if ! grep -Fxq "Paths=/data/addons/StaticMeshes/*.usx" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/StaticMeshes/*.usx' /data/config/UT2004.ini
fi
if ! grep -Fxq "Paths=/data/addons/Music/*.umx" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/Music/*.umx' /data/config/UT2004.ini
fi
if ! grep -Fxq "Paths=/data/addons/Sounds/*.uax" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/Sounds/*.uax' /data/config/UT2004.ini
fi
if ! grep -Fxq "Paths=/data/addons/Textures/*.utx" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/Textures/*.utx' /data/config/UT2004.ini
fi
if ! grep -Fxq "Paths=/data/addons/Maps/*.ut2" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/Maps/*.ut2' /data/config/UT2004.ini
fi
if ! grep -Fxq "Paths=/data/addons/System/*.u" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a Paths=/data/addons/System/*.u' /data/config/UT2004.ini
fi

# If $CD_KEY is defined, update the server key
if ! [ -z ${CD_KEY+x} ]; then
    echo \"CDKey\"=\"${CD_KEY}\" > /data/config/cdkey
fi

# If $COMPRESS_DIR is defined, compress.sh will compress files into it
/app/compress.sh

# Finally, run the server
echo "Starting server..."
exec ./ucc-bin server "${SERVER_START_COMMAND}${SERVER_START_EXTRAS}" ini=UT2004.ini -nohomedir
