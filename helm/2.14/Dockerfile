FROM registry.access.redhat.com/ubi8/ubi AS TIMEZONE

FROM openshift/origin-cli:v3.11 AS OC_CLIENT

FROM golang:1.12 as SKOPEO

ARG SKOPEO_VERSION=v0.1.35

# From https://github.com/containers/skopeo/blob/master/Dockerfile.build
RUN apt-get update && apt-get install -y curl \
      libgpgme11-dev \
      libglib2.0-dev \
      libostree-dev

RUN mkdir -p $GOPATH/src/github.com/containers/skopeo \
    && curl -LsSf https://github.com/containers/skopeo/archive/${SKOPEO_VERSION}.tar.gz | tar xz --strip-components=1 -C $GOPATH/src/github.com/containers/skopeo \
    && cd $GOPATH/src/github.com/containers/skopeo && make binary-local DISABLE_CGO=1

FROM registry.access.redhat.com/ubi8/ubi-minimal

LABEL maintainer="Yannick Siewe" \
      org.label-schema.schema-version="1.0" \
      org.label-.license="MIT"

ENV TERM=xterm \
    HELM_HOME=/var/local/lib/helm/ \
    KUBECONFIG=/var/local/lib/kube/config \
    HOME=/tmp

ARG HELM_VERSION=v2.14.2
ARG HELM_DIFF_VERSION=v2.11.0+5
ARG HELM_PUSH_VERSION=0.7.1
ARG HELM_SECRETS_VERSION=1.3.1
ARG HELM_TILLER_VERSION=0.8.3

#COPY root /

COPY --from=OC_CLIENT /usr/bin/oc /usr/local/bin/oc
COPY --from=SKOPEO /go/src/github.com/containers/skopeo/skopeo /usr/local/bin/skopeo

# https://bugzilla.redhat.com/show_bug.cgi?id=1611117
COPY --from=TIMEZONE /usr/share/zoneinfo/UTC /usr/share/zoneinfo/UTC
COPY --from=TIMEZONE /usr/share/zoneinfo/Europe/Berlin /usr/share/zoneinfo/Europe/Berlin

RUN set -euo pipefail \
    && mkdir -p "${HELM_HOME}" "$(dirname "$KUBECONFIG")" \
    && echo -e '[docker-ce-stable]\nname=Docker CE Stable - $basearch\nbaseurl=https://download.docker.com/linux/centos/7/$basearch/stable\nenabled=0\ngpgcheck=1\ngpgkey=https://download.docker.com/linux/centos/gpg' > /etc/yum.repos.d/docker-ce.repo \
    && microdnf update -y \
    && microdnf install -y --enablerepo=docker-ce-stable git docker-ce-cli python2-pip python2-pyyaml gettext tar unzip procps-ng findutils \
    && microdnf clean all \
## Install kubernetes helm
    && curl -LsSf -O https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf helm-${HELM_VERSION}-linux-amd64.tar.gz linux-amd64 \
    && helm init --client-only \
    && helm repo remove local \
## Install helm plugins (manual installation without GH API)
    && mkdir "$(helm home)/plugins/helm-push" \
    && curl -LsSf https://github.com/chartmuseum/helm-push/releases/download/v${HELM_PUSH_VERSION}/helm-push_${HELM_PUSH_VERSION}_linux_amd64.tar.gz | tar -C "$(helm home)/plugins/helm-push" -zxf- \
    && curl -LsSf https://github.com/databus23/helm-diff/releases/download/${HELM_DIFF_VERSION}/helm-diff-linux.tgz | tar -C "$(helm home)/plugins" --warning=no-unknown-keyword -zxf- \
    && curl -LsSf https://github.com/rimusz/helm-tiller/archive/v${HELM_TILLER_VERSION}.tar.gz| tar -C "$(helm home)/plugins" -xzf- \
    && curl -LsSf https://github.com/futuresimple/helm-secrets/archive/v${HELM_SECRETS_VERSION}.tar.gz | tar -C "$(helm home)/plugins" -xzf- \
    && helm tiller install \
    && chmod -R go+rw "$(helm home)" "$(dirname "$KUBECONFIG")"

USER 1001
