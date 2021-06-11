FROM debian:buster-20210511-slim

RUN apt update \
    &&  apt install -y jq

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
