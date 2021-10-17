#!/usr/bin/env bash

set -euo pipefail

DATA_DIR=/data
SERVER_DIR=/server
VERSION_FILE="${SERVER_DIR}/version.txt"
mkdir -p "${SERVER_DIR}"
pushd "${SERVER_DIR}"

app_id=294420

steamcmd() {
  "${STEAMCMDDIR}/steamcmd.sh" \
    +@ShutdownOnFailedCommand 1 \
    +@NoPromptForPassword 1 \
    +login anonymous \
    "${@}"
}

fetch_build_id() {
  if [[ -z "${VERSION-}" ]] || [[ "${VERSION}" == stable ]]; then
    branch=public
  else
    branch="${VERSION}"
  fi

  steamcmd \
    +app_info_update 1 \
    +app_info_print "${app_id}" \
    +quit | \
      sed '1,/"branches"/d' | \
      sed "1,/\"${branch}\"/d" | \
      sed '/\}/q' | \
      sed -n -E 's/.*"buildid"\s+"([0-9]+)".*/\1/p'
}

update() {
  steamcmd \
    +force_install_dir "${SERVER_DIR}" \
    +app_update "${app_id}" ${VERSION+-beta "${VERSION}"} -validate \
    +quit

  echo "${1}" > "${VERSION_FILE}"
}

update_if_needed() {
  latest_version="$(fetch_build_id)"

  if installed_version="$(cat "${VERSION_FILE}" 2>/dev/null)"; then
    if [[ "${installed_version}" -eq "${latest_version}" ]]; then
      echo "Server version ${installed_version} is up-to-date."
      return
    fi

    echo "Updating server from version ${installed_version} to ${latest_version}."
  else
    echo "Installing server version ${latest_version} …"
  fi

  update "${latest_version}"
}

update_if_needed

while IFS='=' read -r name value ; do
  if [[ "${name}" =~ ^7D2D_ ]]; then
    declare "${name/#7D2D_/SDTD_}=${value}"
  fi
done < <(env)

MODS_DIR="${DATA_DIR}/Mods"
mkdir -p "${MODS_DIR}"
ln -sfn "${MODS_DIR}" Mods

# These are needed for the graceful shutdown script.
export SDTD_TELNET_PORT="${SDTD_TELNET_PORT-8081}"
export SDTD_TELNET_PASSWORD="${SDTD_TELNET_PASSWORD-CHANGEME}"

cat > serverconfig.xml <<EOF
<?xml version="1.0"?>
<ServerSettings>
  <!-- GENERAL SERVER SETTINGS -->

  <!-- Server Representation -->
  <property name="ServerName"                         value="${SDTD_SERVER_NAME-}"/>
  <property name="ServerDescription"                  value="${SDTD_SERVER_DESCRIPTION-A 7 Days to Die server}"/>
  <property name="ServerWebsiteURL"                   value="${SDTD_SERVER_WEBSITE_URL-}"/>
  <property name="ServerPassword"                     value="${SDTD_SERVER_PASSWORD-}"/>
  <property name="ServerLoginConfirmationText"        value="${SDTD_SERVER_LOGIN_CONFIRMATION_TEXT-}"/>

  <!-- Networking -->
  <property name="ServerVisibility"                   value="${SDTD_SERVER_VISIBILITY-2}"/>
  <property name="ServerDisabledNetworkProtocols"     value="${SDTD_SERVER_DISABLED_NETWORK_PROTOCOLS-SteamNetworking}"/>
  <property name="ServerMaxWorldTransferSpeedKiBs"    value="${SDTD_SERVER_MAX_WORLD_DOWNLOAD_SPEED_KIBS-512}"/>
  <property name="ServerIP"                           value="${SDTD_SERVER_IP-0.0.0.0}"/>
  <property name="ServerPort"                         value="${SDTD_SERVER_PORT-26900}"/>
  <property name="ConnectToServerIP"                  value="${SDTD_CONNECT_TO_SERVER_IP-0.0.0.0}"/>
  <property name="ConnectToServerPort"                value="${SDTD_CONNECT_TO_SERVER_PORT-26900}"/>

  <!-- Slots -->
  <property name="ServerMaxPlayerCount"               value="${SDTD_SERVER_MAX_PLAYER_COUNT-8}"/>
  <property name="ServerReservedSlots"                value="${SDTD_SERVER_RESERVED_SLOTS-0}"/>
  <property name="ServerReservedSlotsPermission"      value="${SDTD_SERVER_RESERVED_SLOTS_PERMISSION-100}"/>
  <property name="ServerAdminSlots"                   value="${SDTD_SERVER_ADMIN_SLOTS-0}"/>
  <property name="ServerAdminSlotsPermission"         value="${SDTD_SERVER_ADMIN_SLOTS_PERMISSION-0}"/>

  <!-- Admin Interfaces -->
  <property name="ControlPanelEnabled"                value="${SDTD_CONTROL_PANEL_ENABLED-false}"/>
  <property name="ControlPanelPort"                   value="${SDTD_CONTROL_PANEL_PORT-8080}"/>
  <property name="ControlPanelPassword"               value="${SDTD_CONTROL_PANEL_PASSWORD-CHANGEME}"/>

  <property name="TelnetEnabled"                      value="true"/>
  <property name="TelnetPort"                         value="${SDTD_TELNET_PORT}"/>
  <property name="TelnetPassword"                     value="${SDTD_TELNET_PASSWORD}"/>
  <property name="TelnetFailedLoginLimit"             value="${SDTD_TELNET_FAILED_LOGIN_LIMIT-10}"/>
  <property name="TelnetFailedLoginsBlocktime"        value="${SDTD_TELNET_FAILED_LOGINS_BLOCKTIME-10}"/>

  <property name="TerminalWindowEnabled"              value="false"/>

  <!-- Folder and File Locations -->
  <property name="AdminFileName"                      value="serveradmin.xml"/>
  <property name="UserDataFolder"                     value="/data"/>

  <!-- Other Technical Settings -->
  <property name="EACEnabled"                         value="${SDTD_EAC_ENABLED-true}"/>
  <property name="HideCommandExecutionLog"            value="${SDTD_HIDE_COMMAND_EXECUTION_LOG-0}"/>
  <property name="MaxUncoveredMapChunksPerPlayer"     value="${SDTD_MAX_UNCOVERED_MAP_CHUNKS_PER_PLAYER-131072}"/>
  <property name="PersistentPlayerProfiles"           value="${SDTD_PERSISTENT_PLAYER_PROFILES-false}"/>

  <!-- GAMEPLAY -->

  <!-- World -->
  <property name="GameWorld"                           value="${SDTD_GAME_WORLD-Navezgane}"/>
  <property name="WorldGenSeed"                        value="${SDTD_WORLD_GEN_SEED-asdf}"/>
  <property name="WorldGenSize"                        value="${SDTD_WORLD_GEN_SIZE-4096}"/>
  <property name="GameName"                            value="${SDTD_GAME_NAME-My Game}"/>
  <property name="GameMode"                            value="${SDTD_GAME_MODE-GameModeSurvival}"/>

  <!-- Difficulty -->
  <property name="GameDifficulty"                      value="${SDTD_GAME_DIFFICULTY-2}"/>
  <property name="BlockDamagePlayer"                   value="${SDTD_BLOCK_DAMAGE_PLAYER-100}"/>
  <property name="BlockDamageAI"                       value="${SDTD_BLOCK_DAMAGE_AI-100}"/>
  <property name="BlockDamageAIBM"                     value="${SDTD_BLOCK_DAMAGE_AIBM-100}"/>
  <property name="XPMultiplier"                        value="${SDTD_XP_MULTIPLIER-100}"/>
  <property name="PlayerSafeZoneLevel"                 value="${SDTD_PLAYER_SAFE_ZONE_LEVEL-5}"/>
  <property name="PlayerSafeZoneHours"                 value="${SDTD_PLAYER_SAFE_ZONE_HOURS-5}"/>

  <!--  -->
  <property name="BuildCreate"                         value="${SDTD_BUILD_CREATE-false}"/>
  <property name="DayNightLength"                      value="${SDTD_DAY_NIGHT_LENGTH-60}"/>
  <property name="DayLightLength"                      value="${SDTD_DAY_LIGHT_LENGTH-18}"/>
  <property name="DropOnDeath"                         value="${SDTD_DROP_ON_DEATH-0}"/>
  <property name="DropOnQuit"                          value="${SDTD_DROP_ON_QUIT-0}"/>
  <property name="BedrollDeadZoneSize"                 value="${SDTD_BEDROLL_DEAD_ZONE_SIZE-15}"/>

  <!-- Performance Related -->
  <property name="MaxSpawnedZombies"                   value="${SDTD_MAX_SPAWNED_ZOMBIES-60}"/>
  <property name="MaxSpawnedAnimals"                   value="${SDTD_MAX_SPAWNED_ANIMALS-50}"/>

  <!-- Zombie Settings -->
  <property name="EnemySpawnMode"                      value="${SDTD_ENEMY_SPAWN_MODE-true}"/>
  <property name="EnemyDifficulty"                     value="${SDTD_ENEMY_DIFFICULTY-0}"/>
  <property name="ZombieMove"                          value="${SDTD_ZOMBIE_MOVE-0}"/>
  <property name="ZombieMoveNight"                     value="${SDTD_ZOMBIE_MOVE_NIGHT-3}"/>
  <property name="ZombieFeralMove"                     value="${SDTD_ZOMBIE_FERAL_MOVE-3}"/>
  <property name="ZombieBMMove"                        value="${SDTD_ZOMBIE_BM_MOVE-3}"/>
  <property name="BloodMoonFrequency"                  value="${SDTD_BLOOD_MOON_FREQUENCY-7}"/>
  <property name="BloodMoonRange"                      value="${SDTD_BLOOD_MOON_RANGE-0}"/>
  <property name="BloodMoonWarning"                    value="${SDTD_BLOOD_MOON_WARNING-8}"/>
  <property name="BloodMoonEnemyCount"                 value="${SDTD_BLOOD_MOON_ENEMY_COUNT-8}"/>

  <!-- Loot -->
  <property name="LootAbundance"                       value="${SDTD_LOOT_ABUNDANCE-100}"/>
  <property name="LootRespawnDays"                     value="${SDTD_LOOT_RESPAWN_DAYS-30}"/>
  <property name="AirDropFrequency"                    value="${SDTD_AIR_DROP_FREQUENCY-72}"/>
  <property name="AirDropMarker"                       value="${SDTD_AIR_DROP_MARKER-false}"/>

  <!-- Multiplayer -->
  <property name="PartySharedKillRange"                value="${SDTD_PARTY_SHARED_KILL_RANGE-100}"/>
  <property name="PlayerKillingMode"                   value="${SDTD_PLAYER_KILLING_MODE-3}"/>

  <!-- Land Claim Options -->
  <property name="LandClaimCount"                      value="${SDTD_LAND_CLAIM_COUNT-1}"/>
  <property name="LandClaimSize"                       value="${SDTD_LAND_CLAIM_SIZE-41}"/>
  <property name="LandClaimDeadZone"                   value="${SDTD_LAND_CLAIM_DEAD_ZONE-30}"/>
  <property name="LandClaimExpiryTime"                 value="${SDTD_LAND_CLAIM_EXPIRY_TIME-3}"/>
  <property name="LandClaimDecayMode"                  value="${SDTD_LAND_CLAIM_DECAY_MODE-0}"/>
  <property name="LandClaimOnlineDurabilityModifier"   value="${SDTD_LAND_CLAIM_ONLINE_DURABILITY_MODIFIER-4}"/>
  <property name="LandClaimOfflineDurabilityModifier"  value="${SDTD_LAND_CLAIM_OFFLINE_DURABILITY_MODIFIER-4}"/>
</ServerSettings>
EOF

export LD_LIBRARY_PATH=.

exit_code=0
./7DaysToDieServer.x86_64 \
  -configfile=./serverconfig.xml \
  -logfile /dev/stdout \
  -quit \
  -batchmode \
  -nographics \
  -dedicated &
server_pid=$!

wait_for_server() {
  wait "${server_pid}" || exit_code=$?
  exit "${exit_code}"
}

graceful_shutdown() {
  signal="${1}"
  echo "Received ${signal}, shutting down."
  /graceful-shutdown || kill "${server_pid}"
  wait_for_server
}

trap 'graceful_shutdown SIGINT' INT
trap 'graceful_shutdown SIGTERM' TERM

wait_for_server
