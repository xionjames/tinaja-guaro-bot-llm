# A small OpenAI-compatible chat server: llama.cpp's llama-server with a model baked into the image.
# BASE_IMAGE picks the variant: ghcr.io/ggml-org/llama.cpp:server (CPU) or :server-cuda (NVIDIA).
ARG BASE_IMAGE=ghcr.io/ggml-org/llama.cpp:server

# Download the model in its own stage, so changing the server settings below doesn't download it again
FROM ${BASE_IMAGE} AS model
ARG MODEL_REPO=google/gemma-4-E2B-it-qat-q4_0-gguf
ARG MODEL_REVISION=675cff42a74c774d6cb76f76d8eacb49b48c9b93
ARG MODEL_FILE=gemma-4-E2B_q4_0-it.gguf
RUN curl -fL --retry 3 -o /model.gguf "https://huggingface.co/${MODEL_REPO}/resolve/${MODEL_REVISION}/${MODEL_FILE}"

FROM ${BASE_IMAGE}
ARG MODEL_ALIAS=gemma-4-e2b-it
COPY --from=model /model.gguf /models/model.gguf

# Every setting is a llama-server env var, so `docker run -e LLAMA_ARG_...` overrides it.
# The defaults keep RAM low (the 3.35 GB Gemma 4 E2B file, RAM use not measured): a 4K-token context instead of the model's own, much larger one.
ENV LLAMA_ARG_MODEL=/models/model.gguf \
    LLAMA_ARG_ALIAS=${MODEL_ALIAS} \
    LLAMA_ARG_HOST=0.0.0.0 \
    LLAMA_ARG_PORT=8080 \
    LLAMA_ARG_CTX_SIZE=4096 \
    LLAMA_ARG_N_PARALLEL=1 \
    LLAMA_ARG_CACHE_RAM=0 \
    LLAMA_ARG_REASONING=off

USER 1001:1001
EXPOSE 8080
