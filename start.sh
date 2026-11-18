#!/bin/bash
set -e

# 1. Restore sesi login Binance Agentic Wallet
mkdir -p "$HOME/.baw"
echo "$BAW_SESSION_B64" | base64 -d > /tmp/baw.tar.gz
tar -xzf /tmp/baw.tar.gz -C "$HOME"
rm -f /tmp/baw.tar.gz
chmod 700 "$HOME/.baw"
baw wallet status --json || true

# 2. Setup OpenClaw & Provider Model (Gemini 3.1 Flash Lite)
mkdir -p "$HOME/.openclaw/workspace"
openclaw onboard --non-interactive --accept-risk \
  --auth-choice groq-api-key \
  --groq-api-key "$GROQ_API_KEY" \
  --skip-channels --skip-skills --skip-daemon || true

openclaw config set agents.defaults.models '{"google/gemini-3.1-flash-lite":{},"google/gemini-3.5-flash-lite":{},"google/gemini-3.7-flash":{},"google/gemini-3.8-flash":{}}' --strict-json --merge || true
openclaw models set google/gemini-3.1-flash-lite || true
openclaw models fallbacks add google/gemini-3.5-flash-lite || true
openclaw models fallbacks add google/gemini-3.7-flash || true
openclaw models fallbacks add google/gemini-3.8-flash || true

# 3. Hubungkan Channel Telegram Native OpenClaw (Real-time 24/7)
openclaw config set channels.telegram "{\"enabled\":true,\"botToken\":\"$TELEGRAM_BOT_TOKEN\",\"dmPolicy\":\"allowlist\",\"allowFrom\":[\"$TELEGRAM_CHAT_ID\"]}" --strict-json --merge || true

cp /app/AGENTS.md "$HOME/.openclaw/workspace/AGENTS.md"
cat <<EOF > "$HOME/.openclaw/.env"
GEMINI_API_KEY=${GEMINI_API_KEY}
GROQ_API_KEY=${GROQ_API_KEY}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
EOF
chmod 600 "$HOME/.openclaw/.env"

# 4. Install 3 Skill Inti Binance Web3
cd "$HOME/.openclaw/workspace"
npx -y skills add binance/binance-skills-hub/skills/binance-web3 --all --agent '*' -y
rm -rf "$HOME/.openclaw/workspace/skills"
mkdir -p "$HOME/.openclaw/workspace/skills"
for s in binance-agentic-wallet query-token-audit query-token-info; do
  cp -r "$HOME/.openclaw/workspace/.agents/skills/$s" "$HOME/.openclaw/workspace/skills/"
done
rm -rf "$HOME/.openclaw/workspace/.agents"

# 5. Server HTTP kecil di port 7860 untuk Health Check Koyeb
node -e 'require("http").createServer((_,res)=>{res.writeHead(200);res.end("Binance Agent 24/7 Active");}).listen(7860);' &

# 6. Loop Patroli Otonom tiap 15 menit di background
(
  sleep 20
  while true; do
    cd "$HOME/.openclaw/workspace"
    openclaw agent --message "Patroli rutin: periksa status wallet & sisa gas menggunakan baw CLI, lalu cek peluang terbaru untuk Free Mint (NFT & Token), Klaim khusus pemegang Agent ID, dan Kampanye Tugas Agent. Ikuti aturan ketat di AGENTS.md. Kirim laporan singkat ke Telegram jika ada peluang valid atau aksi yang dieksekusi." || true
    sleep 900
  done
) &

# 7. Jalankan Gateway OpenClaw utama (mendengarkan chat Telegram secara real-time)
exec openclaw gateway run
