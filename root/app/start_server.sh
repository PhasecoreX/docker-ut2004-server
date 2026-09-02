#!/usr/bin/env sh
set -euf

# Check if the user actually volume/bind mounted the /data directory
if [ "$(stat -c "%d" /)" -eq "$(stat -c "%d" /data)" ]; then
    echo ""
    echo "Try reading the instructions before running this image!" >&2
    exit 1
fi

# Download/update server files
/app/install.sh /data/server

# Switch to the server System directory, make server executible
cd /data/server/System
chmod +x ./ucc-bin

# Make config and addons directories if they don't exist
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
set +f
find /data/addons/System/ /data/server/System/ -type f \( -name '*.ini' -o -name 'cdkey' \) -exec mv -n -t /data/config {} +
rm -f /data/addons/System/*.ini /data/server/System/*.ini /data/server/System/cdkey
ln -s /data/config/* /data/server/System/
set -f

# Fix up (users) UT2004.ini to have /data/addons folders defined
if ! grep -Fxq "CacheRecordPath=/data/addons/System/*.ucl" /data/config/UT2004.ini; then
    sed -i '/\[Core.System\]/a CacheRecordPath=/data/addons/System/*.ucl' /data/config/UT2004.ini
fi
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

# Replace old Epic Games servers if they exist
if grep -Fxq "MasterServerList=(Address=\"ut2004master1.epicgames.com\",Port=28902)" /data/config/UT2004.ini; then
    sed -i '/MasterServerList=(Address="ut2004master1.epicgames.com",Port=28902)/c\MasterServerList=(Address="utmaster.openspy.net",Port=28902)' /data/config/UT2004.ini
fi
if grep -Fxq "MasterServerList=(Address=\"ut2004master2.epicgames.com\",Port=28902)" /data/config/UT2004.ini; then
    sed -i '/MasterServerList=(Address="ut2004master2.epicgames.com",Port=28902)/c\MasterServerList=(Address="master.frag-net.com",Port=28902)' /data/config/UT2004.ini
fi

# If $SERVER_NAME is defined, set server name to this value
if [ -n "${SERVER_NAME:-}" ]; then
    sed -i "/\[Engine.GameReplicationInfo\]/,/^$/s/^ServerName=.*/ServerName=${SERVER_NAME}/" /data/config/UT2004.ini
fi

# Function to enable web interface
enable_web_interface() {
    if [ -z "${ADMIN_PASSWORD:-}" ]; then
        echo "WARNING: ENABLE_WEB_INTERFACE is true but ADMIN_PASSWORD is not set - skipping web interface setup" >&2
        return
    fi
    sed -i '/\[UWeb.WebServer\]/,/^$/s/bEnabled=.*/bEnabled=True/' /data/config/UT2004.ini
    sed -i "/\[Engine.AccessControl\]/,/^$/s/^AdminPassword=.*/AdminPassword=${ADMIN_PASSWORD}/" /data/config/UT2004.ini
}

# Function to disable web interface
disable_web_interface() {
    sed -i '/\[UWeb.WebServer\]/,/^$/s/bEnabled=.*/bEnabled=False/' /data/config/UT2004.ini
}

# If $ENABLE_WEB_INTERFACE is defined, enable or disable the web interface accordingly
if [ "${ENABLE_WEB_INTERFACE:-}" = "true" ]; then
    enable_web_interface
elif [ "${ENABLE_WEB_INTERFACE:-}" = "false" ]; then
    disable_web_interface
fi

# xVoting configuration to add for Map Voting
MAP_VOTING_CONFIG='
[xVoting.xVotingHandler]
VoteTimeLimit=30
ScoreBoardDelay=10
bAutoOpen=True
MidGameVotePercent=50
bScoreMode=False
bAccumulationMode=False
bEliminationMode=False
MinMapCount=2
MapVoteHistoryType=xVoting.MapVoteHistory_INI
RepeatLimit=4
DefaultGameConfig=0
bDefaultToCurrentGameType=True
bMapVote=True
bKickVote=False
bMatchSetup=False
KickPercent=51
bAnonymousKicking=True
MapListLoaderType=xVoting.DefaultMapListLoader
ServerNumber=1
CurrentGameConfig=0
GameConfig=(GameClass="XGame.xCTFGame",Prefix="CTF",Acronym="CTF",GameName="Capture The Flag",Mutators=,Options=)
GameConfig=(GameClass="XGame.xCTFGame",Prefix="CTF",Acronym="CTF",GameName="Capture The Flag InstaGib",Mutators="XGame.MutInstaGib",Options=)
GameConfig=(GameClass="Onslaught.ONSOnslaughtGame",Prefix="ONS",Acronym="ONS",GameName="Onslaught",Mutators=,Options=)
GameConfig=(GameClass="XGame.xDeathMatch",Prefix="DM",Acronym="DM",GameName="DeathMatch",Mutators=,Options=)
GameConfig=(GameClass="XGame.xDeathMatch",Prefix="DM",Acronym="DM",GameName="DeathMatch InstaGib",Mutators="XGame.MutInstaGib",Options=)
GameConfig=(GameClass="XGame.xBombingRun",Prefix="BR",Acronym="BR",GameName="Bombing Run",Mutators=,Options=)
GameConfig=(GameClass="UT2k4Assault.ASGameInfo",Prefix="AS",Acronym="AS",GameName="Assualt",Mutators=,Options=)
GameConfig=(GameClass="XGame.xDoubleDom",Prefix="DOM",Acronym="DOM",GameName="Double Domination",Mutators=,Options=)
GameConfig=(GameClass="XGame.xTeamGame",Prefix="DM",Acronym="DM",GameName="Team DeathMatch",Mutators=,Options=)

[xVoting.DefaultMapListLoader]
bUseMapList=False
MapNamePrefixes=DM,DOM,CTF,BR,AS,ONS
'

# Function to enable map voting
enable_map_voting() {
    if ! grep -q "^\[xVoting\.xVotingHandler\]" "/data/config/UT2004.ini"; then
        # Append map voting configuration if section doesn't exist
        echo "$MAP_VOTING_CONFIG" >> "/data/config/UT2004.ini"
    else
        # Enable map voting if the section exists
        sed -i '/\[xVoting.xVotingHandler\]/,/^$/s/^bMapVote=.*/bMapVote=True/' "/data/config/UT2004.ini"
    fi
}

# Function to disable map voting
disable_map_voting() {
    if grep -q "^\[xVoting\.xVotingHandler\]" "/data/config/UT2004.ini"; then
        # Section exists - just flip the flag off, leave the rest of the config intact
        sed -i '/\[xVoting.xVotingHandler\]/,/^$/s/^bMapVote=.*/bMapVote=False/' "/data/config/UT2004.ini"
    fi
    # If the section doesn't exist at all, voting is already off by default - nothing to do
}

# If $ENABLE_MAP_VOTING is defined, enable or disable map voting accordingly
if [ "${ENABLE_MAP_VOTING:-}" = "true" ]; then
    enable_map_voting
elif [ "${ENABLE_MAP_VOTING:-}" = "false" ]; then
    disable_map_voting
fi

# If $CD_KEY is defined, update the server key
if [ -n "${CD_KEY:-}" ]; then
    echo \"CDKey\"=\""${CD_KEY}"\" >/data/config/cdkey
fi

# If $COMPRESS_DIR is defined, compress.sh will compress files into it
if [ -n "${COMPRESS_DIR:-}" ]; then
    /app/compress.sh "${COMPRESS_DIR}"
fi

# Finally, run the server
echo "Starting server..."
server_command="${MAP_NAME:-"DM-Antalus"}?game=${GAME_TYPE:-"xGame.xDeathMatch"}"
if [ -n "${MUTATORS:-}" ]; then
    server_command="${server_command}?mutator=${MUTATORS}"
fi
exec ./ucc-bin server "${SERVER_START_COMMAND:-"${server_command}"}${SERVER_START_EXTRAS:-}" ini=UT2004.ini -nohomedir -lanplay
