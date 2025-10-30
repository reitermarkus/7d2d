#!/usr/bin/env bash

set -euo pipefail

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

UPDATE_INTERVAL_SECONDS=3600

update_if_needed() {
  local installed_version
  local latest_version

  if installed_version="$(cat "${VERSION_FILE}" 2>/dev/null)"; then
    last_check="$(stat -c %Y "${VERSION_FILE}")"
    now="$(date +%s)"

    if (( (now - last_check) < UPDATE_INTERVAL_SECONDS )); then
      echo "Skipping update check, already checked within the last ${UPDATE_INTERVAL_SECONDS} seconds."
      return
    fi

    latest_version="$(fetch_build_id)"

    if [[ "${installed_version}" -eq "${latest_version}" ]]; then
      echo "Server version ${installed_version} is up-to-date."
      return
    fi

    echo "Updating server from version ${installed_version} to ${latest_version}."
  else
    latest_version="$(fetch_build_id)"

    echo "Installing server version ${latest_version} …"
  fi

  update "${latest_version}"
}

update_if_needed

MODS_DIR="${DATA_DIR}/Mods"
mkdir -p "${MODS_DIR}"
ln -sfn "${MODS_DIR}" Mods

# These are needed for the graceful shutdown script.
export TELNET_PORT="${TELNET_PORT-8081}"
export TELNET_PASSWORD="${TELNET_PASSWORD-CHANGEME}"

cat > serverconfig.xml <<EOF
<?xml version="1.0"?>
<ServerSettings>
  <!-- GENERAL SERVER SETTINGS -->

  <!-- Server Representation -->
  <property name="ServerName"                         value="${SERVER_NAME-}"/>
  <property name="ServerDescription"                  value="${SERVER_DESCRIPTION-A 7 Days to Die server}"/>
  <property name="ServerWebsiteURL"                   value="${SERVER_WEBSITE_URL-}"/>
  <property name="ServerPassword"                     value="${SERVER_PASSWORD-}"/>
  <property name="ServerLoginConfirmationText"        value="${SERVER_LOGIN_CONFIRMATION_TEXT-}"/>

  <!-- Networking -->
  <property name="ServerVisibility"                   value="${SERVER_VISIBILITY-2}"/>
  <property name="ServerDisabledNetworkProtocols"     value="${SERVER_DISABLED_NETWORK_PROTOCOLS-SteamNetworking}"/>
  <property name="ServerMaxWorldTransferSpeedKiBs"    value="${SERVER_MAX_WORLD_DOWNLOAD_SPEED_KIBS-512}"/>
  <property name="ServerIP"                           value="${SERVER_IP-0.0.0.0}"/>
  <property name="ServerPort"                         value="${SERVER_PORT-26900}"/>
  <property name="ConnectToServerIP"                  value="${CONNECT_TO_SERVER_IP-0.0.0.0}"/>
  <property name="ConnectToServerPort"                value="${CONNECT_TO_SERVER_PORT-26900}"/>

  <!-- Slots -->
  <property name="ServerMaxPlayerCount"               value="${SERVER_MAX_PLAYER_COUNT-8}"/>
  <property name="ServerReservedSlots"                value="${SERVER_RESERVED_SLOTS-0}"/>
  <property name="ServerReservedSlotsPermission"      value="${SERVER_RESERVED_SLOTS_PERMISSION-100}"/>
  <property name="ServerAdminSlots"                   value="${SERVER_ADMIN_SLOTS-0}"/>
  <property name="ServerAdminSlotsPermission"         value="${SERVER_ADMIN_SLOTS_PERMISSION-0}"/>

  <!-- Admin Interfaces -->
  <property name="ControlPanelEnabled"                value="${CONTROL_PANEL_ENABLED-false}"/>
  <property name="ControlPanelPort"                   value="${CONTROL_PANEL_PORT-8080}"/>
  <property name="ControlPanelPassword"               value="${CONTROL_PANEL_PASSWORD-CHANGEME}"/>

  <property name="TelnetEnabled"                      value="true"/>
  <property name="TelnetPort"                         value="${TELNET_PORT}"/>
  <property name="TelnetPassword"                     value="${TELNET_PASSWORD}"/>
  <property name="TelnetFailedLoginLimit"             value="${TELNET_FAILED_LOGIN_LIMIT-10}"/>
  <property name="TelnetFailedLoginsBlocktime"        value="${TELNET_FAILED_LOGINS_BLOCKTIME-10}"/>

  <property name="TerminalWindowEnabled"              value="false"/>

  <!-- Folder and File Locations -->
  <property name="AdminFileName"                      value="serveradmin.xml"/>
  <property name="UserDataFolder"                     value="/data"/>

  <!-- Other Technical Settings -->
  <property name="EACEnabled"                         value="${EAC_ENABLED-true}"/>
  <property name="HideCommandExecutionLog"            value="${HIDE_COMMAND_EXECUTION_LOG-0}"/>
  <property name="MaxUncoveredMapChunksPerPlayer"     value="${MAX_UNCOVERED_MAP_CHUNKS_PER_PLAYER-131072}"/>
  <property name="PersistentPlayerProfiles"           value="${PERSISTENT_PLAYER_PROFILES-false}"/>

  <!-- GAMEPLAY -->

  <!-- World -->
  <property name="GameWorld"                           value="${GAME_WORLD-Navezgane}"/>
  <property name="WorldGenSeed"                        value="${WORLD_GEN_SEED-asdf}"/>
  <property name="WorldGenSize"                        value="${WORLD_GEN_SIZE-4096}"/>
  <property name="GameName"                            value="${GAME_NAME-My Game}"/>
  <property name="GameMode"                            value="${GAME_MODE-GameModeSurvival}"/>

  <!-- Difficulty -->
  <property name="GameDifficulty"                      value="${GAME_DIFFICULTY-2}"/>
  <property name="BlockDamagePlayer"                   value="${BLOCK_DAMAGE_PLAYER-100}"/>
  <property name="BlockDamageAI"                       value="${BLOCK_DAMAGE_AI-100}"/>
  <property name="BlockDamageAIBM"                     value="${BLOCK_DAMAGE_AIBM-100}"/>
  <property name="XPMultiplier"                        value="${XP_MULTIPLIER-100}"/>
  <property name="PlayerSafeZoneLevel"                 value="${PLAYER_SAFE_ZONE_LEVEL-5}"/>
  <property name="PlayerSafeZoneHours"                 value="${PLAYER_SAFE_ZONE_HOURS-5}"/>

  <!--  -->
  <property name="BuildCreate"                         value="${BUILD_CREATE-false}"/>
  <property name="DayNightLength"                      value="${DAY_NIGHT_LENGTH-60}"/>
  <property name="DayLightLength"                      value="${DAY_LIGHT_LENGTH-18}"/>
  <property name="DropOnDeath"                         value="${DROP_ON_DEATH-0}"/>
  <property name="DropOnQuit"                          value="${DROP_ON_QUIT-0}"/>
  <property name="BedrollDeadZoneSize"                 value="${BEDROLL_DEAD_ZONE_SIZE-15}"/>

  <!-- Performance Related -->
  <property name="MaxSpawnedZombies"                   value="${MAX_SPAWNED_ZOMBIES-60}"/>
  <property name="MaxSpawnedAnimals"                   value="${MAX_SPAWNED_ANIMALS-50}"/>

  <!-- Zombie Settings -->
  <property name="EnemySpawnMode"                      value="${ENEMY_SPAWN_MODE-true}"/>
  <property name="EnemyDifficulty"                     value="${ENEMY_DIFFICULTY-0}"/>
  <property name="ZombieMove"                          value="${ZOMBIE_MOVE-0}"/>
  <property name="ZombieMoveNight"                     value="${ZOMBIE_MOVE_NIGHT-3}"/>
  <property name="ZombieFeralMove"                     value="${ZOMBIE_FERAL_MOVE-3}"/>
  <property name="ZombieBMMove"                        value="${ZOMBIE_BM_MOVE-3}"/>
  <property name="BloodMoonFrequency"                  value="${BLOOD_MOON_FREQUENCY-7}"/>
  <property name="BloodMoonRange"                      value="${BLOOD_MOON_RANGE-0}"/>
  <property name="BloodMoonWarning"                    value="${BLOOD_MOON_WARNING-8}"/>
  <property name="BloodMoonEnemyCount"                 value="${BLOOD_MOON_ENEMY_COUNT-8}"/>

  <!-- Loot -->
  <property name="LootAbundance"                       value="${LOOT_ABUNDANCE-100}"/>
  <property name="LootRespawnDays"                     value="${LOOT_RESPAWN_DAYS-30}"/>
  <property name="AirDropFrequency"                    value="${AIR_DROP_FREQUENCY-72}"/>
  <property name="AirDropMarker"                       value="${AIR_DROP_MARKER-false}"/>

  <!-- Multiplayer -->
  <property name="PartySharedKillRange"                value="${PARTY_SHARED_KILL_RANGE-100}"/>
  <property name="PlayerKillingMode"                   value="${PLAYER_KILLING_MODE-3}"/>

  <!-- Land Claim Options -->
  <property name="LandClaimCount"                      value="${LAND_CLAIM_COUNT-1}"/>
  <property name="LandClaimSize"                       value="${LAND_CLAIM_SIZE-41}"/>
  <property name="LandClaimDeadZone"                   value="${LAND_CLAIM_DEAD_ZONE-30}"/>
  <property name="LandClaimExpiryTime"                 value="${LAND_CLAIM_EXPIRY_TIME-3}"/>
  <property name="LandClaimDecayMode"                  value="${LAND_CLAIM_DECAY_MODE-0}"/>
  <property name="LandClaimOnlineDurabilityModifier"   value="${LAND_CLAIM_ONLINE_DURABILITY_MODIFIER-4}"/>
  <property name="LandClaimOfflineDurabilityModifier"  value="${LAND_CLAIM_OFFLINE_DURABILITY_MODIFIER-4}"/>
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
