ARG BUILDER_IMAGE

FROM ${BUILDER_IMAGE} AS builder

ARG VERSION

WORKDIR /work
COPY . .

RUN mkdir -p /dist
RUN make PREFIX=/dist cmds

FROM registry.ddbuild.io/images/nvidia-cuda-base:12.9.0

ARG VERSION

LABEL maintainers="Compute"

COPY --from=builder /dist/* /usr/bin/

USER root

RUN ln -s /usr/bin/nvidia-ctk-installer /usr/local/bin/nvidia-toolkit

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

### ENV args for the toolkit ###
# Only run install and skip containerd configuration
ENV NO_SETUP=true
# Direct install with apt in the image
ENV TOOLKIT_SOURCE_ROOT=/

RUN ORIGINAL_VERSION=${VERSION%%-*} && apt-get update && apt-get install -y nvidia-container-toolkit=${ORIGINAL_VERSION#v}-1

CMD [ "/usr/local/bin/nvidia-toolkit" ]
