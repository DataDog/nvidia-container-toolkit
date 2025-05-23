ARG BUILDER_IMAGE

FROM ${BUILDER_IMAGE} AS builder

ARG VERSION

WORKDIR /work
COPY . .

RUN GOPATH=/artifacts go install -ldflags="-w -X 'main.Version=${VERSION}'" ./tools/...

RUN mkdir -p /dist
RUN make PREFIX=/dist cmds

FROM registry.ddbuild.io/images/nvidia-cuda-base:12.9.0

ARG VERSION

LABEL maintainers="Compute"

COPY --from=builder /artifacts/bin/nvidia-toolkit /usr/bin/nvidia-toolkit
COPY --from=builder /dist/* /usr/bin/

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

RUN ORIGINAL_VERSION=${VERSION%%-*} && apt-get update && apt-get install -y nvidia-container-toolkit=${ORIGINAL_VERSION#v}-1

CMD [ "/usr/bin/nvidia-toolkit" ]
