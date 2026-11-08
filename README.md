# Tinaja Guaro Bot LLM
A small local language model behind an **OpenAI-compatible API** (`/v1/chat/completions`, `/v1/models`) for
[Tinaja Guaro Bot](https://github.com/xionjames/tinaja-guaro-bot). It chats in Spanish and English and doesn't "think" out loud.

- **Model**: [Gemma 4 E2B](https://huggingface.co/google/gemma-4-E2B-it) (Apache-2.0), 4-bit. It is the cheaper
  default: a smaller file and less RAM than Gemma 4 E4B, the previous default. In the bot's earlier comparison
  (Qwen3-4B, Gemma 4 E4B and E2B), E4B made up the fewest facts and E2B made up more, so switch back to E4B
  (see Build) if that matters more than cost. It thinks before answering by default, so both servers switch thinking off.
- **Server**: llama.cpp's `llama-server` for Docker, `mlx_lm.server` for Apple Silicon.

| Variant | Runs on | How | Resources |
| --- | --- | --- | --- |
| `cpu` | any amd64/arm64 machine, including Docker on a Mac | `docker compose up -d cpu` | not measured with E2B |
| `cuda` | Linux + NVIDIA GPU + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/) | `docker compose --profile cuda up -d cuda` | not tested here |
| `mlx` | Apple Silicon, **native** (no Docker) | `./mlx/serve.sh` | not measured with E2B |

Docker on macOS has no GPU access, so MLX can't run in a container; `mlx/serve.sh` runs it natively with
[uv](https://docs.astral.sh/uv/) on the same port and API. All variants listen on `http://localhost:8080/v1`.

## Access
The server has **no API key**, so by default it only accepts connections from the machine it runs on: compose
publishes `127.0.0.1:8080` and `mlx/serve.sh` binds `127.0.0.1`. To share the model with other machines:
- **Docker**: in `compose.yaml` change `'127.0.0.1:8080:8080'` to `'8080:8080'`, and require a key by adding
  `LLAMA_ARG_API_KEY: <a long random string>` under the service's `environment:`. Clients then send it as
  `Authorization: Bearer <key>` (the bot's `LLM_API_KEY`).
- **MLX**: `HOST=0.0.0.0 ./mlx/serve.sh`. As far as I know `mlx_lm.server` has no API-key option, so only do this on a
  network you trust.

## Use it from the bot
In the bot's `.env`:
```bash
LLM_BASE_URL=http://localhost:8080/v1              # the bot in Docker on a Mac: http://host.docker.internal:8080/v1
LLM_MODEL=default_model                            # "the model the server loaded", for llama-server and MLX alike
```
Use `default_model` (or the exact MLX repo id): `mlx_lm.server` treats any other name as a Hugging Face repo to download.

## Build
```bash
docker compose build cpu
docker compose --profile cuda build cuda           # add --platform linux/amd64 for x86 NVIDIA hosts
```
The model is downloaded at build time and baked in, so the image runs offline. Change it with build args, e.g.
```bash
docker build --build-arg MODEL_REPO=unsloth/Qwen3-4B-Instruct-2507-GGUF \
  --build-arg MODEL_FILE=Qwen3-4B-Instruct-2507-Q4_K_M.gguf --build-arg MODEL_REVISION=main \
  --build-arg MODEL_ALIAS=qwen3-4b-instruct -t tinaja-guaro-bot-llm:cpu-qwen .
```
Qwen3-4B-Instruct-2507 is another lighter option (~3 GB RAM) but makes up more facts.
To go back to Gemma 4 E4B (the bigger, previous default: fewer made-up facts, more RAM):
```bash
docker build --build-arg MODEL_REPO=google/gemma-4-E4B-it-qat-q4_0-gguf \
  --build-arg MODEL_FILE=gemma-4-E4B_q4_0-it.gguf \
  --build-arg MODEL_REVISION=4b4a2c1d584be7264f87aac328a1bc739ce81b6c \
  --build-arg MODEL_ALIAS=gemma-4-e4b-it -t tinaja-guaro-bot-llm:cpu-e4b .
```
For MLX: `MODEL=mlx-community/gemma-4-e4b-it-4bit ./mlx/serve.sh`.
`MODEL_REVISION` pins the Hugging Face commit; set it to `main` when changing `MODEL_REPO`.

## Tune
Every server setting is a `llama-server` env var, overridable with `docker run -e` or `environment:` in compose:

| Var | Default | Notes |
| --- | --- | --- |
| `LLAMA_ARG_CTX_SIZE` | `4096` | Tokens of context; more context = more RAM |
| `LLAMA_ARG_N_PARALLEL` | `1` | Requests answered at the same time (they share the context) |
| `LLAMA_ARG_CACHE_RAM` | `0` | Prompt cache in MiB; off to save RAM |
| `LLAMA_ARG_THREADS` | auto | CPU threads |
| `LLAMA_ARG_N_GPU_LAYERS` | `99` in `cuda` | Layers on the GPU |
| `LLAMA_ARG_REASONING` | `off` | No thinking |

The MLX script reads `MODEL`, `HOST`, `PORT` and `CHAT_TEMPLATE_ARGS` (default `{"enable_thinking": false}`).
For a model without a thinking mode, the argument is simply ignored.

## Check it
```bash
./scripts/smoke.sh                                 # or ./scripts/smoke.sh http://other-host:8080/v1
```
It asks one question in Spanish and one in English.
