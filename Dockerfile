FROM node:24-slim

RUN apt-get update && apt-get install -y \
    curl git tar gzip python3 make g++ ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @binance/agentic-wallet@1.12.0 openclaw@latest

WORKDIR /app
COPY AGENTS.md /app/AGENTS.md
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 7860

CMD ["/app/start.sh"]
