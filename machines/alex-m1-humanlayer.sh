#!/bin/bash
# Runs self-hosted HumanLayer (~/dev/humanlayer) on alex-m1. launchd starts this
# at login and restarts it when it exits. See machines/alex-m1.md.
#
# Browsers and the WorkOS redirects use https://<tailnet name>:<port>, served by
# `tailscale serve` with real certificates. The daemon on this box talks to the
# API and sync proxy over loopback, so it needs neither Tailscale nor a trusted
# local CA. The web apps run as production builds; the API, sync proxy and
# daemon run from source and restart when their files change.
#
# `--local` swaps the tailnet origins for http://localhost ones, for testing on
# this box without Tailscale.
set -euo pipefail

REPO="$HOME/dev/humanlayer"
LOGS="$HOME/.humanlayer/riptide/logs/main"
export PATH="/opt/homebrew/bin:/usr/local/bin:/etc/profiles/per-user/$(id -un)/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export LANG="${LANG:-en_US.UTF-8}"
MODE=tailnet
[ "${1:-}" = --local ] && MODE=local
cd "$REPO"
mkdir -p "$LOGS"

log() { printf '%s humanlayer: %s\n' "$(date '+%F %T')" "$*"; }
# Keep each log under 50 MB across restarts.
for f in "$LOGS"/{api,sync,daemon,ui,cloud}.log; do
  if [ -f "$f" ] && [ "$(stat -f %z "$f")" -gt 52428800 ]; then mv -f "$f" "$f.1"; fi
done

until docker info >/dev/null 2>&1; do
  log "starting OrbStack"; orbctl start >/dev/null 2>&1 || true; sleep 5
done
if [ "$MODE" = tailnet ]; then
  until [ "$(tailscale status --json 2>/dev/null | jq -r .BackendState)" = Running ]; do
    log "waiting for Tailscale"; sleep 5
  done
fi

# Starts the containers and applies database migrations. Safe to repeat.
mise exec -- bun --bun run devstack sync --compose

env_value() { grep "^$1=" .env | tail -1 | cut -d= -f2-; }
UI_PORT=$(env_value RIPTIDE_UI_PORT)
CLOUD_PORT=$(env_value RIPTIDE_CLOUD_PORT)
API_PORT=$(env_value RIPTIDE_API_PORT)
SYNC_PORT=$(env_value RIPTIDE_ELECTRIC_PROXY_PORT)
S3_PORT=$(env_value DEVSTACK_MINIO_API_PORT)

if [ "$MODE" = tailnet ]; then
  HOST=$(tailscale status --json | jq -r '.Self.DNSName | rtrimstr(".")')
  APP="https://$HOST" CLOUD="https://$HOST:8443" API="https://$HOST:8444"
  SYNC="https://$HOST:8445" S3="https://$HOST:8446"
  tailscale serve --bg --https=443 "http://127.0.0.1:$UI_PORT" >/dev/null
  tailscale serve --bg --https=8443 "http://127.0.0.1:$CLOUD_PORT" >/dev/null
  tailscale serve --bg --https=8444 "http://127.0.0.1:$API_PORT" >/dev/null
  tailscale serve --bg --https=8445 "http://127.0.0.1:$SYNC_PORT" >/dev/null
  tailscale serve --bg --https=8446 "http://127.0.0.1:$S3_PORT" >/dev/null
else
  HOST=localhost
  APP="http://localhost:$UI_PORT" CLOUD="http://localhost:$CLOUD_PORT" API="http://localhost:$API_PORT"
  SYNC="http://localhost:$SYNC_PORT" S3="http://localhost:$S3_PORT"
fi

# Process env beats the devstack block in .env for Bun and Vite alike.
export APP_ORIGIN="$APP" RIPTIDE_APP_ORIGIN="$APP" RIPTIDE_ELECTRON_RENDERER_URL="$APP"
export CLOUD_ORIGIN="$CLOUD" VITE_PUBLIC_CLOUD_ORIGIN="$CLOUD" RIPTIDE_CLOUD_ORIGIN="$CLOUD"
export RIPTIDE_API_ORIGIN="$API" VITE_PUBLIC_RIPTIDE_API_ORIGIN="$API"
export RIPTIDE_SYNC_ORIGIN="$SYNC" VITE_PUBLIC_SYNC_ORIGIN="$SYNC"
export S3_ARTIFACTS_ENDPOINT="$S3"
export WORKOS_REDIRECT_URI="$CLOUD/auth/callback"
# Drop devstack touches meant for throwaway stacks: the "main" tab title and
# colored favicon, and Haiku as the default Claude model.
export VITE_PUBLIC_DEVSTACK_ID= VITE_PUBLIC_DEVSTACK_COLOR= VITE_PUBLIC_DEVSTACK_OVERRIDE_DEFAULT_CLAUDE_MODEL=
# Vite only answers Host headers it knows; tailscale serve passes the tailnet name.
export __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS="$HOST"

pids=()
trap 'trap - EXIT; kill 0' EXIT TERM INT
start() { # start <name> <dir> <command...>
  local name=$1 dir=$2; shift 2
  (cd "$dir" && exec "$@") >>"$LOGS/$name.log" 2>&1 &
  pids+=($!)
}

start api apps/riptide-api mise exec -- bun run dev
start sync apps/riptide-electric-proxy mise exec -- bun run dev

# The daemon passes its whole environment to every Claude Code session, so it
# gets only what it needs: no ANTHROPIC_API_KEY (sessions bill the Claude
# subscription), no WorkOS or Stripe keys. PATH comes from a login shell so
# sessions see the same tools as a terminal.
SESSION_PATH=$(/bin/zsh -lic 'print -r -- $PATH' 2>/dev/null | tail -1)
start daemon apps/riptide-daemon env -i \
  HOME="$HOME" USER="$(id -un)" LOGNAME="$(id -un)" SHELL=/bin/zsh LANG="$LANG" \
  TMPDIR="${TMPDIR:-/tmp}" PATH="${SESSION_PATH:-$PATH}" \
  LOG_BASE="$(env_value LOG_BASE)" DEVSTACK_ID="$(env_value DEVSTACK_ID)" \
  NODE_USE_SYSTEM_CA=1 RIPTIDE_DAEMON_FORCE_LOCAL_PLUGIN=true \
  RIPTIDE_DAEMON_LOAD_CREDS=true \
  RIPTIDE_DAEMON_USER_ID="${HUMANLAYER_DAEMON_USER_ID:-$(env_value RIPTIDE_DAEMON_USER_ID)}" \
  RIPTIDE_DAEMON_ORGANIZATION_ID="$(env_value RIPTIDE_DAEMON_ORGANIZATION_ID)" \
  RIPTIDE_DAEMON_TOKEN_PRIVATE_KEY="$(env_value RIPTIDE_DAEMON_TOKEN_PRIVATE_KEY)" \
  RIPTIDE_API_ORIGIN="http://127.0.0.1:$API_PORT" RIPTIDE_DAEMON_API_ORIGIN="http://127.0.0.1:$API_PORT" \
  RIPTIDE_SYNC_ORIGIN="http://127.0.0.1:$SYNC_PORT" RIPTIDE_DAEMON_SYNC_ORIGIN="http://127.0.0.1:$SYNC_PORT" \
  RIPTIDE_APP_ORIGIN="$APP" RIPTIDE_DAEMON_APP_ORIGIN="$APP" \
  RIPTIDE_CLOUD_ORIGIN="$CLOUD" RIPTIDE_DAEMON_CLOUD_ORIGIN="$CLOUD" \
  /opt/homebrew/bin/mise exec -- bun --bun --watch run src/daemon.ts

log "building web apps"
(cd apps/riptide-ui && VITE_PUBLIC_BUILD_TYPE=local VITE_PUBLIC_DEEP_LINK_SCHEME=riptide-local \
  VITE_PUBLIC_REMOTE_DAEMON_BUILD_TYPE=local mise exec -- bun --bun run vite build) >>"$LOGS/ui.log" 2>&1
(cd apps/riptide-cloud && mise exec -- bun --bun --env-file=../../.env run vite build) >>"$LOGS/cloud.log" 2>&1
start ui apps/riptide-ui mise exec -- bun --bun run vite preview --host 127.0.0.1 --port "$UI_PORT" --strictPort
start cloud apps/riptide-cloud mise exec -- bun --bun --env-file=../../.env run vite preview --host 127.0.0.1 --port "$CLOUD_PORT" --strictPort

log "running at $APP"
# Exit when any process dies; launchd then restarts the whole set.
while sleep 10; do
  for pid in "${pids[@]}"; do
    kill -0 "$pid" 2>/dev/null || { log "process $pid exited, restarting"; exit 1; }
  done
done
