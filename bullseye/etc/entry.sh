#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true

# Download Updates

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
				+login "${STEAMUSER}" "${STEAMPASS}" "${STEAMGUARD}" \
				+app_update "${STEAMAPPID}" \
				+quit

# steamclient.so fix
mkdir -p ~/.steam/sdk64
ln -sfT ${STEAMCMDDIR}/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

# Install server.cfg
cp /etc/server.cfg "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg
sed -i -e "s/{{SERVER_HOSTNAME}}/${CS2_SERVERNAME}/g" "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg \
       -e "s/{{SERVER_PW}}/${CS2_PW}/g" "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg \
       -e "s/{{SERVER_RCON_PW}}/${CS2_RCONPW}/g" "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg \
       -e "s/{{SERVER_LAN}}/${CS2_LAN}/g" "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg

# Rewrite Config Files

if [[ ! -z $CS2_BOT_DIFFICULTY ]] ; then
    sed -i "s/bot_difficulty.*/bot_difficulty ${CS2_BOT_DIFFICULTY}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA ]] ; then
    sed -i "s/bot_quota.*/bot_quota ${CS2_BOT_QUOTA}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA_MODE ]] ; then
    sed -i "s/bot_quota_mode.*/bot_quota_mode ${CS2_BOT_QUOTA_MODE}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi

# Switch to server directory
cd "${STEAMAPPDIR}/game/bin/linuxsteamrt64"

# Construct server arguments

if [[ -z $CS2_GAMEALIAS ]]; then
    # If CS2_GAMEALIAS is undefined then default to CS2_GAMETYPE and CS2_GAMEMODE
    CS2_GAME_MODE_ARGS="+game_type ${CS2_GAMETYPE} +game_mode ${CS2_GAMEMODE}"
else
    # Else, use alias to determine game mode
    CS2_GAME_MODE_ARGS="+game_alias ${CS2_GAMEALIAS}"
fi

# Start Server

if [[ ! -z $CS2_RCON_PORT ]]; then
    echo "Establishing Simpleproxy for ${CS2_RCON_PORT} to 127.0.0.1:${CS2_PORT}"
    simpleproxy -L "${CS2_RCON_PORT}" -R 127.0.0.1:"${CS2_PORT}" &
fi

eval "./cs2" -dedicated \
        -ip "${CS2_IP}" -port "${CS2_PORT}" \
        -console \
        -usercon \
        -maxplayers "${CS2_MAXPLAYERS}" \
        "${CS2_GAME_MODE_ARGS}" \
        +mapgroup "${CS2_MAPGROUP}" \
        +map "${CS2_STARTMAP}" \
        +rcon_password "${CS2_RCONPW}" \
        +sv_password "${CS2_PW}" \
        "${CS2_ADDITIONAL_ARGS}"
