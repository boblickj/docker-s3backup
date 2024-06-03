FROM debian:bookworm
MAINTAINER Jason Boblick <jason.boblick@outlook.com>

ENV DEBIAN_FRONTEND="noninteractive" HOME="/root" LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates cron s3cmd && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data

ADD run.sh /

ENTRYPOINT ["/run.sh"]
CMD ["start"]
