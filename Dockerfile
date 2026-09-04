FROM mikefarah/yq:4.53.6 AS yq-source
FROM almir/webhook:2.8.3 AS webhook-source

FROM ghcr.io/linuxserver/baseimage-alpine:3.24

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
