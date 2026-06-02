#!/usr/bin/env bash
# =============================================================================
# SNRobotiX LLM Box — TRIAL setup (no domain, no HTTPS)
# Ollama + Open WebUI + Hermes Agent, all local. Reach the web UI via SSH tunnel.
#
# RUN AS YOUR NON-ROOT USER (e.g. sherif) WITH SUDO. Not as root.
# Prereqs:
#   1. Fresh Ubuntu 24 on the VPS.
#   2. Non-root sudo user created (PHASE 0 block at the bottom).
#
# Usage:
#   chmod +x setup-trial.sh
#   ./setup-trial.sh
#
# After it finishes, from YOUR LAPTOP open a tunnel:
#   ssh -L 8080:127.0.0.1:8080 sherif@YOUR_SERVER_IP
# then browse on your laptop to:  http://localhost:8080
# =============================================================================

set -euo pipefail

c_info()  { printf '\033[0;36m→\033[0m %s\n' "$1"; }
c_ok()    { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
c_warn()  { printf '\033[0;33m⚠\033[0m %s\n' "$1"; }
c_err()   { printf '\033[0;31m✗\033[0m %s\n' "$1"; }
c_step()  { printf '\n\033[1;35m=== %s ===\033[0m\n' "$1"; }

if [ "$(id -u)" -eq 0 ]; then
  c_err "Do NOT run this as root. Run it as your sudo user (e.g. sherif)."
  c_info "See the PHASE 0 block at the bottom of this file to create that user."
  exit 1
fi

# ----- model choices ---------------------------------------------------------
WEBUI_MODEL="qwen2.5-coder:14b"        # interactive coding in the browser
AGENT_BASE_MODEL="qwen2.5-coder:32b"   # base for the agent's 64k variant
AGENT_MODEL="qwen2.5-coder-64k"        # 64k-context variant Hermes will use
AGENT_CTX=64000                        # Hermes hard minimum for agent/tool use

c_step "TRIAL setup — no domain, no HTTPS"
c_info "Web UI model: $WEBUI_MODEL"
c_info "Agent model:  $AGENT_MODEL (64k ctx, built from $AGENT_BASE_MODEL)"
c_info "Web UI will be reachable ONLY via SSH tunnel (instructions at the end)."
echo
read -rp "Proceed? [y/N] " GO
case "$GO" in y|Y|yes|YES) ;; *) c_err "Aborted."; exit 1;; esac

# =============================================================================
c_step "1. System update + base packages"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ufw fail2ban git build-essential python3-dev libffi-dev ripgrep ffmpeg curl ca-certificates
c_ok "Base packages installed"

# =============================================================================
c_step "2. Firewall (ONLY SSH open — no web ports exposed)"
sudo ufw allow OpenSSH
sudo ufw --force enable
c_ok "UFW enabled. Only SSH (22) is open. Web UI stays private behind the tunnel."

# =============================================================================
c_step "3. Install Ollama"
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
else
  c_info "Ollama already present, skipping"
fi
sudo systemctl enable --now ollama
sleep 3
systemctl is-active --quiet ollama && c_ok "Ollama running" || { c_err "Ollama failed: systemctl status ollama"; exit 1; }

# =============================================================================
c_step "4. Pull models (downloads several GB; be patient)"
c_info "Pulling web UI model: $WEBUI_MODEL"
ollama pull "$WEBUI_MODEL"
c_info "Pulling agent base model: $AGENT_BASE_MODEL"
ollama pull "$AGENT_BASE_MODEL"
c_info "Creating 64k-context variant '$AGENT_MODEL'"
TMP_MODELFILE="$(mktemp)"
cat > "$TMP_MODELFILE" <<EOF
FROM $AGENT_BASE_MODEL
PARAMETER num_ctx $AGENT_CTX
EOF
ollama create "$AGENT_MODEL" -f "$TMP_MODELFILE"
rm -f "$TMP_MODELFILE"
c_ok "Models ready"

# =============================================================================
c_step "5. Install Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  c_warn "Added $USER to docker group; log out/in later to use docker without sudo."
else
  c_info "Docker already present, skipping"
fi

# =============================================================================
c_step "6. Run Open WebUI — bound to LOCALHOST ONLY (127.0.0.1:8080)"
# Critical difference from the full setup: we publish to 127.0.0.1 only, so the
# port is NOT reachable from the internet even though no Nginx sits in front.
if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
  c_info "Recreating existing open-webui container"
  sudo docker rm -f open-webui
fi
sudo docker run -d \
  --name open-webui \
  -p 127.0.0.1:8080:8080 \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e WEBUI_AUTH=True \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main
sleep 5
sudo docker ps --format '{{.Names}}' | grep -q '^open-webui$' \
  && c_ok "Open WebUI running on 127.0.0.1:8080 (private)" \
  || { c_err "Open WebUI failed: sudo docker logs open-webui"; exit 1; }

# =============================================================================
c_step "7. Install Hermes Agent (as $USER, skip browser engine)"
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
  | bash -s -- --skip-browser --skip-setup
export PATH="$HOME/.local/bin:$PATH"
command -v hermes >/dev/null 2>&1 || { c_err "hermes not found; run 'source ~/.bashrc' and retry from step 8 manually."; exit 1; }
c_ok "Hermes installed"

# =============================================================================
c_step "8. Point Hermes at local Ollama (/v1 suffix is mandatory)"
hermes config set model.provider custom
hermes config set model.base_url http://localhost:11434/v1
hermes config set model.default "$AGENT_MODEL"
hermes config set model.context_length "$AGENT_CTX"
ENV_FILE="$HOME/.hermes/.env"
touch "$ENV_FILE"; chmod 600 "$ENV_FILE"
grep -q '^HERMES_STREAM_READ_TIMEOUT=' "$ENV_FILE" || echo "HERMES_STREAM_READ_TIMEOUT=1800" >> "$ENV_FILE"
c_ok "Hermes configured to use $AGENT_MODEL"

c_info "Testing local model call (first run may be slow while the model loads)..."
if hermes -z "Reply exactly HERMES_OK" 2>/dev/null | grep -q "HERMES_OK"; then
  c_ok "Hermes reached the local model"
else
  c_warn "No HERMES_OK yet — likely just first-load latency. Retry: hermes -z \"say hi\""
fi

# =============================================================================
c_step "DONE — TRIAL is up"
SERVER_IP="$(curl -fsS4 https://api.ipify.org 2>/dev/null || echo YOUR_SERVER_IP)"
cat <<EOF

Everything runs locally on the box. Nothing web-facing is exposed to the internet.

TO USE THE WEB UI — from YOUR LAPTOP, open an SSH tunnel:

    ssh -L 8080:127.0.0.1:8080 $USER@$SERVER_IP

Leave that terminal open, then in your browser go to:

    http://localhost:8080

  • First account you register becomes ADMIN. Create it, strong password.
  • Pick "$WEBUI_MODEL" from the model dropdown and start coding.
  • Close the SSH session to "disconnect" the web UI. Reopen the tunnel to use it again.

TO USE THE HERMES AGENT — on the server:

    hermes                 # interactive chat, uses local $AGENT_MODEL
    hermes config edit     # change model / add messaging later

PERFORMANCE: the 14B web model is the snappy one for coding. The 32B agent runs
~30–120s per reply on CPU — normal, not broken.

WHEN YOU COMMIT: to go public with a real URL + HTTPS, point a domain's A record
at $SERVER_IP, then install nginx + certbot, add a reverse proxy to 127.0.0.1:8080,
and open ports 80/443 in ufw. That is the only delta from this trial.

To Open to the internet use: sudo ufw allow 8080/tcp
To close again use: sudo ufw delete allow 8080/tcp

EOF
