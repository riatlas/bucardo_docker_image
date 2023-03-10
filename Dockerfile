FROM ubuntu:jammy

LABEL maintainer="lucas@vieira.io"
LABEL version="2.0"

ENV PG_VERSION 14

RUN apt-get -y update \
    && apt-get -y upgrade

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get -y install postgresql-${PG_VERSION} bucardo jq

COPY etc/pg_hba.conf /etc/postgresql/${PG_VERSION}/main/
COPY etc/bucardorc /etc/bucardorc

RUN chown postgres /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
RUN chown postgres /etc/bucardorc
RUN chown postgres /var/log/bucardo
RUN mkdir /var/run/bucardo && chown postgres /var/run/bucardo
RUN usermod -aG bucardo postgres

RUN service postgresql start \
    && su - postgres -c "bucardo install --batch"

COPY lib/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME "/media/bucardo"
CMD ["/bin/bash","-c","/entrypoint.sh"]