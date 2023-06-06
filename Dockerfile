FROM ubuntu:23.04 as dependency

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl ca-certificates gettext-base xz-utils

WORKDIR /compressed/
RUN curl -Lso helm.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz
RUN tar -xf helm.tar.gz

WORKDIR /extract/
RUN curl -Lso kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl
RUN mv /compressed/${TARGETOS}-${TARGETARCH}/helm ./
RUN ls -l

WORKDIR /awscli/
RUN curl -Lso awscliv2.zip https://awscli.amazonaws.com/awscli-exe-${TARGETOS}-x86_64.zip

FROM ubuntu:23.04 as runner
COPY --from=0 /extract/* /usr/local/bin/
WORKDIR /app
COPY --from=0 /awscli/* ./
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates unzip \
    && chmod +x /usr/local/bin/helm /usr/local/bin/kubectl \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update \
    && kubectl version --client \
    && helm version --client \
    && aws --version
CMD bash
# uncomment for debug purpose
# RUN exit 1
