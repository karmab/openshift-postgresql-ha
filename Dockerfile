FROM centos/postgresql-95-centos7

USER root

RUN yum install -y epel-release && \
    yum install -y etcd gcc make ansible python-pip iproute
    
# Install patroni and WAL-e
ENV PATRONIVERSION=1.2.4
ENV WALE_VERSION=1.0.3
ENV PGHOME=/var/lib/pgsql/
ENV PGROOT=$PGHOME/pgdata/pgroot
ENV PGDATA=$PGROOT/data
ENV PGLOG=$PGROOT/pg_log
ENV WALE_ENV_DIR=$PGHOME/etc/wal-e.d/env
ENV USER_NAME=${PGUSER}
ENV USER_UID=26

RUN pip install pip --upgrade && \
    pip install --upgrade patroni==$PATRONIVERSION


#install pg_view
#RUN curl -L https://raw.githubusercontent.com/zalando/pg_view/2ea99479460d81361bdb7601a1564072ddd584ac/pg_view.py \
#    | sed -e 's/env python/env python3/g' > /usr/local/bin/pg_view.py && chmod +x /usr/local/bin/pg_view.py


RUN mv /opt/rh/rh-postgresql95/root/usr/bin/postgres{,-real} && \
    echo '#!/usr/bin/bash' > /opt/rh/rh-postgresql95/root/usr/bin/postgres && \
    cat /opt/rh/rh-postgresql95/enable >> /opt/rh/rh-postgresql95/root/usr/bin/postgres && \
    echo 'exec postgres-real "$@"' >> /opt/rh/rh-postgresql95/root/usr/bin/postgres && \
    chmod 755 /opt/rh/rh-postgresql95/root/usr/bin/postgres

ADD root /

RUN chmod -R ug+x /usr/bin/user_setup /usr/bin/callback.py && \
    /usr/bin/user_setup

ADD entrypoint.yml /var/lib/pgsql/
ADD templates /var/lib/pgsql/templates

USER ${USER_UID}
RUN sed "s@${USER_NAME}:x:${USER_UID}:@${USER_NAME}:x:\${USER_ID}:@g" /etc/passwd > ${HOME}/passwd.template
WORKDIR $PGHOME
EXPOSE 5432 8008




