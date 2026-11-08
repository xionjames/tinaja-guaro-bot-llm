#!/usr/bin/env sh
# Apple Silicon only, runs natively: Docker on macOS has no access to the GPU, so MLX can't run in a container.
# Same model and the same OpenAI-compatible API on the same port as the Docker images.
set -eu
MODEL="${MODEL:-mlx-community/gemma-4-e2b-it-4bit}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"
# Gemma 4 thinks before answering by default in MLX; switch it off (clients can still ask for it per request)
NO_THINKING='{"enable_thinking": false}'
CHAT_TEMPLATE_ARGS="${CHAT_TEMPLATE_ARGS:-$NO_THINKING}"
exec uvx --python 3.12 --from mlx-lm mlx_lm.server --model "$MODEL" --host "$HOST" --port "$PORT" \
  --chat-template-args "$CHAT_TEMPLATE_ARGS"
