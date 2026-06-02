#!/usr/bin/env bash
# =============================================================================
# SNRobotiX LLM Box — snrllm.sh
# Single Contabo VPS setup: Ollama + Open WebUI + Hermes Agent, all local.
#
# Incorporates every fix found during the first build:
#   • Open WebUI runs on --network=host so it reaches Ollama with no
#     host.docker.internal / bridge-routing problems (the thing that broke last time).
#   • OLLAMA_HOST bound to 0.0.0.0 so anything on the host can reach it.
#   • OLLAMA_KEEP_ALIVE=-1 so models stay warm and you skip the cold-load delay.
#   • OpenAI connection disabled by default (no spurious "missing bearer" errors).
#   • Hermes pointed at local Ollama with the mandatory /v1 suffix.
#
# RUN AS YOUR NON-ROOT SUDO USER (e.g. sherif). Not as root.
# Prereqs: fresh Ubuntu 24; non-root sudo user created (PHASE 0 at bottom).
#
# Two modes, chosen by a prompt:
#   TRIAL  — no domain, web UI reached via SSH tunnel (most private).
#   PUBLIC — domain + Nginx + HTTPS, reachable on the internet with login.
#
# Usage:
#   chmod +x snrllm.sh
#   ./snrllm.sh
# =============================================================================

set -euo pipefail

c_info()  { printf '\033[0;36m→\033[0m %s\n' "$1"; }
c_ok()    { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
c_warn()  { printf '\033[0;33m⚠\033[0m %s\n' "$1"; }
c_err()   { printf '\033[0;31m✗\033[0m %s\n' "$1"; }
c_step()  { printf '\n\033[1;35m=== %s ===\033[0m\n' "$1"; }

if [ "$(id -u)" -eq 0 ]; then
  c_err "Do NOT run this as root. Run as your sudo user (e.g. sherif)."
  c_info "See the PHASE 0 block at the bottom of this file to create that user first."
  exit 1
fi

# ----- model choices ---------------------------------------------------------
# 7B  = snappy, good enough for casual/testing and quick coding
# 14B = the daily-driver coding model, the quality/speed sweet spot on CPU
# 32B = best code quality but slow on CPU; base for the agent's 64k variant
WEBUI_FAST_MODEL="qwen2.5-coder:7b"
WEBUI_MAIN_MODEL="qwen2.5-coder:14b"
AGENT_BASE_MODEL="qwen2.5-coder:32b"
AGENT_MODEL="qwen2.5-coder-64k"
AGENT_CTX=64000

# =============================================================================
c_step "Mode selection"
echo "  1) TRIAL  — no domain, reach the web UI over an SSH tunnel (most private)"
echo "  2) PUBLIC — domain + HTTPS, reachable on the internet with login"
read -rp "Choose 1 or 2: " MODE
case "$MODE" in
  1) PUBLIC=0; c_info "TRIAL mode selected" ;;
  2) PUBLIC=1; c_info "PUBLIC mode selected" ;;
  *) c_err "Invalid choice."; exit 1 ;;
esac

if [ "$PUBLIC" -eq 1 ]; then
  read -rp "Domain for the web UI (e.g. llm.yourdomain.com): " DOMAIN
  read -rp "Your email (for Let's Encrypt): " LE_EMAIL
  [ -z "$DOMAIN" ] || [ -z "$LE_EMAIL" ] && { c_err "Domain and email required."; exit 1; }
fi

echo
c_info "Will install: Ollama, models ($WEBUI_FAST_MODEL, $WEBUI_MAIN_MODEL, $AGENT_BASE_MODEL + 64k variant),"
c_info "Open WebUI (host networking), Hermes Agent (local model)."
read -rp "Proceed? [y/N] " GO
case "$GO" in y|Y|yes|YES) ;; *) c_err "Aborted."; exit 1;; esac

# =============================================================================
c_step "1. System update + base packages"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
PKGS="ufw fail2ban git build-essential python3-dev libffi-dev ripgrep ffmpeg curl ca-certificates"
[ "$PUBLIC" -eq 1 ] && PKGS="$PKGS nginx certbot python3-certbot-nginx"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $PKGS
c_ok "Base packages installed"

# =============================================================================
c_step "2. Firewall"
sudo ufw allow OpenSSH
if [ "$PUBLIC" -eq 1 ]; then
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  c_ok "SSH + HTTP + HTTPS open. Ollama(11434)/WebUI(8080) stay internal."
else
  c_ok "Only SSH open. Web UI reached via SSH tunnel; nothing else exposed."
fi
sudo ufw --force enable

# =============================================================================
c_step "3. Install Ollama + bind to all interfaces + keep models warm"
if ! command -v ollama >/dev/null 2>&1; then
  curl -fsSL https://ollama.com/install.sh | sh
else
  c_info "Ollama already present, skipping install"
fi

# Systemd override: bind 0.0.0.0 (so containers/host reach it) and keep models
# loaded indefinitely (no cold-load delay on first message after idle).
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_KEEP_ALIVE=-1"
EOF
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama
sleep 3
if systemctl is-active --quiet ollama; then
  c_ok "Ollama running (bound 0.0.0.0:11434, keep-alive infinite)"
else
  c_err "Ollama failed: systemctl status ollama"; exit 1
fi
# Confirm the env actually took (this is what bit us last time).
if systemctl show ollama | grep -q "OLLAMA_HOST=0.0.0.0:11434"; then
  c_ok "Verified OLLAMA_HOST is set"
else
  c_warn "OLLAMA_HOST not showing in systemctl show — check the override file"
fi

# =============================================================================
c_step "4. Pull models (downloads ~10GB+7GB+19GB; be patient)"
c_info "Pulling $WEBUI_FAST_MODEL (fast/testing)"
ollama pull "$WEBUI_FAST_MODEL"
c_info "Pulling $WEBUI_MAIN_MODEL (daily coding)"
ollama pull "$WEBUI_MAIN_MODEL"
c_info "Pulling $AGENT_BASE_MODEL (agent base)"
ollama pull "$AGENT_BASE_MODEL"

c_info "Creating 64k-context agent variant '$AGENT_MODEL'"
TMP_MODELFILE="$(mktemp)"
cat > "$TMP_MODELFILE" <<EOF
FROM $AGENT_BASE_MODEL
PARAMETER num_ctx $AGENT_CTX
EOF
ollama create "$AGENT_MODEL" -f "$TMP_MODELFILE"
rm -f "$TMP_MODELFILE"
c_ok "All models ready"

# =============================================================================
c_step "5. Install Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  c_warn "Added $USER to docker group; log out/in later for non-sudo docker."
else
  c_info "Docker already present, skipping"
fi

# =============================================================================
c_step "6. Run Open WebUI on HOST NETWORKING (the reliable path)"
# Host networking = container shares host net stack, so Ollama is plain
# 127.0.0.1:11434 with no host.docker.internal/bridge issues. This is the fix
# for the 'Failed to fetch models' problem from the first build.
if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
  c_info "Recreating existing open-webui container"
  sudo docker rm -f open-webui
fi
sudo docker run -d \
  --name open-webui \
  --network=host \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -e WEBUI_AUTH=True \
  -e ENABLE_OPENAI_API=False \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main
sleep 5
sudo docker ps --format '{{.Names}}' | grep -q '^open-webui$' \
  && c_ok "Open WebUI running on host port 8080" \
  || { c_err "Open WebUI failed: sudo docker logs open-webui"; exit 1; }

# Verify the container can actually reach Ollama (the check that caught the bug).
c_info "Verifying Open WebUI -> Ollama connectivity"
if sudo docker exec open-webui curl -s http://127.0.0.1:11434/api/tags | grep -q '"models"'; then
  c_ok "Open WebUI can reach Ollama and sees the models"
else
  c_warn "Could not confirm model list from inside the container; check manually:"
  c_warn "  sudo docker exec open-webui curl -s http://127.0.0.1:11434/api/tags"
fi

# =============================================================================
if [ "$PUBLIC" -eq 1 ]; then
c_step "7. Nginx reverse proxy + HTTPS"
SERVER_IP="$(curl -fsS4 https://api.ipify.org || true)"
RESOLVED_IP="$(getent ahostsv4 "$DOMAIN" | awk '{print $1; exit}' || true)"
c_info "Server IP: ${SERVER_IP:-unknown}   $DOMAIN -> ${RESOLVED_IP:-NOT RESOLVING}"
if [ -z "$RESOLVED_IP" ] || { [ -n "$SERVER_IP" ] && [ "$RESOLVED_IP" != "$SERVER_IP" ]; }; then
  c_err "DNS for $DOMAIN does not point at this server yet. Fix the A record, re-run."
  exit 1
fi
sudo tee /etc/nginx/sites-available/llm >/dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    client_max_body_size 50M;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
    }
}
EOF
sudo ln -sf /etc/nginx/sites-available/llm /etc/nginx/sites-enabled/llm
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$LE_EMAIL" --redirect
c_ok "HTTPS live at https://$DOMAIN (auto-renewing)"
fi

# =============================================================================
c_step "8. Install Hermes Agent (as $USER, skip heavy browser engine)"
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh \
  | bash -s -- --skip-browser --skip-setup
export PATH="$HOME/.local/bin:$PATH"
command -v hermes >/dev/null 2>&1 || { c_err "hermes not found; run 'source ~/.bashrc' then redo from step 9."; exit 1; }
c_ok "Hermes installed"

# =============================================================================
c_step "9. Point Hermes at local Ollama (the /v1 suffix is mandatory)"
hermes config set model.provider custom
hermes config set model.base_url http://localhost:11434/v1
# Default the agent to 14B for usable speed; switch to the 64k variant when you
# actually need the big context for tool-heavy agent work.
hermes config set model.default "$WEBUI_MAIN_MODEL"
hermes config set model.context_length 32768
ENV_FILE="$HOME/.hermes/.env"
touch "$ENV_FILE"; chmod 600 "$ENV_FILE"
grep -q '^HERMES_STREAM_READ_TIMEOUT=' "$ENV_FILE" || echo "HERMES_STREAM_READ_TIMEOUT=1800" >> "$ENV_FILE"
c_ok "Hermes configured (default $WEBUI_MAIN_MODEL; 64k variant '$AGENT_MODEL' available)"

# =============================================================================
c_step "DONE"
SERVER_IP="$(curl -fsS4 https://api.ipify.org 2>/dev/null || echo YOUR_SERVER_IP)"
if [ "$PUBLIC" -eq 1 ]; then
  ACCESS="https://$DOMAIN"
else
  ACCESS="From your laptop:  ssh -L 8080:127.0.0.1:8080 $USER@$SERVER_IP
                     then browse to:  http://localhost:8080"
fi
cat <<EOF

Setup complete.

WEB UI:
  $ACCESS
  • First account you register becomes ADMIN. Create it with a strong password.
  • Model dropdown (top-left of a chat) has:
      $WEBUI_FAST_MODEL   ← fast, for testing / casual use
      $WEBUI_MAIN_MODEL   ← daily coding driver
      $AGENT_BASE_MODEL   ← best quality, slow on CPU
      $AGENT_MODEL        ← 32B with 64k context (agent use)

HERMES AGENT (on the server):
  hermes                 # chat, uses $WEBUI_MAIN_MODEL by default
  hermes config edit     # change model / add Telegram etc.
  # for big-context agent work:  hermes config set model.default $AGENT_MODEL

NOTES BAKED IN THIS TIME:
  • Models stay warm (OLLAMA_KEEP_ALIVE=-1), so no cold-load delay after idle.
    Trade-off: a warm model holds its RAM (~10GB for 14B) on the 48GB box — fine.
  • CPU generation is still single-digit tokens/sec; warmth removes load delay,
    not the per-token speed. Use 7B for snappy, 14B for quality.
  • Open WebUI is on host networking, so model fetching works out of the box.
EOF
if [ "$PUBLIC" -eq 0 ]; then
cat <<EOF

GIVING SOMEONE TEMPORARY INTERNET ACCESS (testing only, plaintext HTTP):
  sudo ufw allow 8080/tcp      # then share  http://$SERVER_IP:8080
  sudo ufw delete allow 8080/tcp   # close it again when done
  (For anything real, use PUBLIC mode for HTTPS instead.)
EOF
fi

cat <<'EOF'

# ---------------------------------------------------------------------------
# PHASE 0 (run ONCE as root on a fresh box BEFORE this script, then log in as
# the new user and run snrllm.sh):
#
#   adduser sherif
#   usermod -aG sudo sherif
#   rsync --archive --chown=sherif:sherif ~/.ssh /home/sherif 2>/dev/null || true
#   su - sherif
# ---------------------------------------------------------------------------
EOF
