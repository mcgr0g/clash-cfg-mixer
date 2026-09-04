ARG ALPINE_VERSION=3.20
ARG YQ_VERSION
ARG WEBHOOK_VERSION=2.8.2

FROM mikefarah/yq:${YQ_VERSION} AS yq-source
FROM almir/webhook:${WEBHOOK_VERSION} AS webhook-source

FROM ghcr.io/linuxserver/baseimage-alpine:${ALPINE_VERSION}

RUN apk add --no-cache curl bash

COPY --from=yq-source /usr/bin/yq /usr/bin/yq
COPY --from=webhook-source /usr/local/bin/webhook /usr/local/bin/webhook

COPY mix.sh /usr/local/bin/mix.sh
RUN chmod +x /usr/local/bin/mix.sh

COPY hooks.json /etc/webhook/hooks.json

RUN mkdir -p /etc/services.d/webhook && \
    echo -e '#!/usr/bin/with-contenv bash\nexec s6-setuidgid abc /usr/local/bin/webhook -port 2026 -verbose -template -hooks=/etc/webhook/hooks.json -hotreload' > /etc/services.d/webhook/run && \
    chmod +x /etc/services.d/webhook/run

EXPOSE 2026
