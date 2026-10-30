#!/usr/bin/env sh
# Ask the server one question in Spanish and one in English: ./scripts/smoke.sh [base_url]
# "default_model" means "the model the server loaded" for both llama-server and mlx_lm.server
set -eu
BASE_URL="${1:-http://localhost:8080/v1}"

ask() {
  curl -fsS "$BASE_URL/chat/completions" -H 'Content-Type: application/json' \
    -d "{\"model\": \"default_model\", \"max_tokens\": 120, \"messages\": [{\"role\": \"user\", \"content\": \"$1\"}]}" \
    | python3 -c 'import json, sys; print(json.load(sys.stdin)["choices"][0]["message"]["content"])'
}

curl -fsS "$BASE_URL/models" >/dev/null
echo '--- ES'; ask '¿Qué es un proxy inverso? Responde en dos frases.'
echo '--- EN'; ask 'What is a reverse proxy? Answer in two sentences.'
