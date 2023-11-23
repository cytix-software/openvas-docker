FROM debian:bookworm-slim

# define mostly static environmental variables
ENV DEBIAN_FRONTEND=noninteractive \
    INSTALL_PREFIX=/usr/local \
    PATH=$PATH:/usr/local/sbin \
    SOURCE_DIR=$HOME/sources \
    BUILD_DIR=$HOME/build \
    INSTALL_DIR=$HOME/install \
    GVM_LIBS_VERSION=22.7.3 \
    GVMD_VERSION=23.0.0 \
    PG_GVM_VERSION=22.6.1 \
    GSA_VERSION=22.8.0 \
    GSAD_VERSION=22.7.0 \
    OPENVAS_SMB_VERSION=22.5.3 \
    OPENVAS_SCANNER_VERSION=22.7.5 \
    OSPD_OPENVAS_VERSION=22.6.0 \
    NOTUS_VERSION=22.6.0 \
    GNUPGHOME=/tmp/openvas-gnupg \
    OPENVAS_GNUPG_HOME=/etc/openvas/gnupg \
    PKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config

# define arguments for build process (see README.md for more)
ARG FEED_PROVISION=init \
    GVM_ADMIN_PASSWORD=password

# install curl and gnupg
RUN apt-get update -y && \
    apt-get -y install curl gnupg

# add external repos for required libraries
RUN curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sS https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | apt-key add - && \
    echo "deb https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# install system dependencies
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get -y install  \
    build-essential \
    curl \
    cmake \
    pkg-config \
    python3 \
    python3-pip \
    gnupg \
    libglib2.0-dev \
    libgpgme-dev \
    libgnutls28-dev \
    uuid-dev \
    libssh-gcrypt-dev \
    libhiredis-dev \
    libxml2-dev \
    libpcap-dev \
    libnet1-dev \
    libpaho-mqtt-dev \
    libldap2-dev \
    libradcli-dev \
    libpq-dev \
    postgresql-server-dev-15 \
    libical-dev \
    xsltproc \
    rsync \
    libbsd-dev \
    texlive-latex-extra \
    texlive-fonts-recommended \
    xmlstarlet \
    zip \
    rpm \
    fakeroot \
    dpkg \
    nsis \
    gpgsm \
    wget \
    sshpass \
    openssh-client \
    socat \
    snmp \
    smbclient \
    python3-lxml \
    gnutls-bin \
    xml-twig-tools \
    libmicrohttpd-dev \
    gcc-mingw-w64 \
    libpopt-dev \
    libunistring-dev \
    heimdal-dev \
    perl-base \
    bison \
    libgcrypt20-dev \
    libksba-dev \
    nmap \
    libjson-glib-dev \
    python3-impacket \
    libsnmp-dev \
    python3-setuptools \
    python3-packaging \
    python3-wrapt \
    python3-cffi \
    python3-psutil \
    python3-defusedxml \
    python3-paramiko \
    python3-redis \
    python3-gnupg \
    python3-paho-mqtt \
    python3-venv \
    git \
    redis-server \
    mosquitto \
    sudo

# create and cd tmp gvm directory
RUN mkdir -p ${BUILD_DIR} && mkdir -p ${SOURCE_DIR} && mkdir -p ${INSTALL_DIR}

# wget all repos
RUN curl -f -L https://github.com/greenbone/gvm-libs/archive/refs/tags/v$GVM_LIBS_VERSION.tar.gz -o $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/gvmd/archive/refs/tags/v$GVMD_VERSION.tar.gz -o $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/pg-gvm/archive/refs/tags/v$PG_GVM_VERSION.tar.gz -o $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/gsa/releases/download/v$GSA_VERSION/gsa-dist-$GSA_VERSION.tar.gz -o $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/gsad/archive/refs/tags/v$GSAD_VERSION.tar.gz -o $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/openvas-smb/archive/refs/tags/v$OPENVAS_SMB_VERSION.tar.gz -o $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_SCANNER_VERSION.tar.gz -o $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/ospd-openvas/archive/refs/tags/v$OSPD_OPENVAS_VERSION.tar.gz -o $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz ;\
    curl -f -L https://github.com/greenbone/notus-scanner/archive/refs/tags/v$NOTUS_VERSION.tar.gz -o $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz

# extract all gvm repos
WORKDIR ${SOURCE_DIR}
RUN tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvm-libs-$GVM_LIBS_VERSION.tar.gz ;\
    tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gvmd-$GVMD_VERSION.tar.gz ;\
    tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/pg-gvm-$PG_GVM_VERSION.tar.gz ;\
    mkdir -p $SOURCE_DIR/gsa-$GSA_VERSION ;\
    tar -C $SOURCE_DIR/gsa-$GSA_VERSION -xvzf $SOURCE_DIR/gsa-$GSA_VERSION.tar.gz ;\
    tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/gsad-$GSAD_VERSION.tar.gz ;\
    tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz ;\
    tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz ;\
    tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz ;\
    tar -C $SOURCE_DIR -xvzf $SOURCE_DIR/notus-scanner-$NOTUS_VERSION.tar.gz

# move to opt
WORKDIR /opt/gvm

# compile gvm libs
RUN mkdir -p ${BUILD_DIR}/gvm-libs && cd ${BUILD_DIR}/gvm-libs ;\
    cmake ${SOURCE_DIR}/gvm-libs-${GVM_LIBS_VERSION} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
        -DCMAKE_BUILD_TYPE=Release \
        -DSYSCONFDIR=/etc \
        -DLOCALSTATEDIR=/var ;\
    make -j$(nproc) ;\
    mkdir -p ${INSTALL_DIR}/gvm-libs ;\
    make DESTDIR=${INSTALL_DIR}/gvm-libs install ;\
    rsync -Ka ${INSTALL_DIR}/gvm-libs/* /

# compile gvmd
RUN mkdir -p ${BUILD_DIR}/gvmd && cd ${BUILD_DIR}/gvmd ;\
    cmake ${SOURCE_DIR}/gvmd-${GVMD_VERSION} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
        -DCMAKE_BUILD_TYPE=Release \
        -DLOCALSTATEDIR=/var \
        -DSYSCONFDIR=/etc \
        -DGVM_DATA_DIR=/var \
        -DGVMD_RUN_DIR=/run/gvmd \
        -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
        -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock \
        -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
        -DLOGROTATE_DIR=/etc/logrotate.d ;\
    make -j$(nproc) ;\
    mkdir -p ${INSTALL_DIR}/gvmd ;\
    make DESTDIR=${INSTALL_DIR}/gvmd install ;\
    rsync -Ka ${INSTALL_DIR}/gvmd/* /

# build pg-gvm
RUN mkdir -p ${BUILD_DIR}/pg-gvm && cd ${BUILD_DIR}/pg-gvm ;\
    cmake ${SOURCE_DIR}/pg-gvm-${PG_GVM_VERSION} \
    -DCMAKE_BUILD_TYPE=Release ;\
    make -j$(nproc) ;\
    mkdir -p ${INSTALL_DIR}/pg-gvm ;\
    make DESTDIR=${INSTALL_DIR}/pg-gvm install ;\
    rsync -Ka ${INSTALL_DIR}/pg-gvm/* /

# build gsa
RUN mkdir -p ${INSTALL_PREFIX}/share/gvm/gsad/web/ ;\
    rsync -Ka ${SOURCE_DIR}/gsa-${GSA_VERSION}/* ${INSTALL_PREFIX}/share/gvm/gsad/web/

# compile gsad
RUN mkdir -p ${BUILD_DIR}/gsad && cd ${BUILD_DIR}/gsad ;\
    cmake ${SOURCE_DIR}/gsad-${GSAD_VERSION} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DGVMD_RUN_DIR=/run/gvmd \
    -DGSAD_RUN_DIR=/run/gsad \
    -DLOGROTATE_DIR=/etc/logrotate.d ;\
    make -j$(nproc) ;\
    mkdir -p ${INSTALL_DIR}/gsad ;\
    make DESTDIR=${INSTALL_DIR}/gsad install ;\
    rsync -Ka ${INSTALL_DIR}/gsad/* /

# compile smb
RUN mkdir -p $BUILD_DIR/openvas-smb && cd $BUILD_DIR/openvas-smb ;\
    cmake $SOURCE_DIR/openvas-smb-$OPENVAS_SMB_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release ;\
    make -j$(nproc) ;\
    mkdir -p $INSTALL_DIR/openvas-smb ;\
    make DESTDIR=$INSTALL_DIR/openvas-smb install ;\
    rsync -Ka $INSTALL_DIR/openvas-smb/* /

# compile scanner
RUN mkdir -p $BUILD_DIR/openvas-scanner && cd $BUILD_DIR/openvas-scanner ;\
    cmake $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION \
    -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DINSTALL_OLD_SYNC_SCRIPT=OFF \
    -DSYSCONFDIR=/etc \
    -DLOCALSTATEDIR=/var \
    -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
    -DOPENVAS_RUN_DIR=/run/ospd ;\
    make -j$(nproc) ;\
    mkdir -p $INSTALL_DIR/openvas-scanner ;\
    make DESTDIR=$INSTALL_DIR/openvas-scanner install ;\
    rsync -Ka $INSTALL_DIR/openvas-scanner/* /

# compile ospd
RUN cd $SOURCE_DIR/ospd-openvas-$OSPD_OPENVAS_VERSION ;\
    mkdir -p $INSTALL_DIR/ospd-openvas ;\
    python3 -m pip install --root=$INSTALL_DIR/ospd-openvas --no-warn-script-location . ;\
    rsync -Ka $INSTALL_DIR/ospd-openvas/* /

# build notus
RUN cd $SOURCE_DIR/notus-scanner-$NOTUS_VERSION ;\
    mkdir -p ${INSTALL_DIR}/notus-dir ;\
    python3 -m pip install --root=$INSTALL_DIR/notus-scanner --no-warn-script-location . ;\
    rsync -Ka $INSTALL_DIR/notus-scanner/* /

# install greenbone-feed-sync
RUN mkdir -p ${INSTALL_DIR}/greenbone-feed-sync ;\
    python3 -m pip install --root=${INSTALL_DIR}/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync ;\
    rsync -Ka $INSTALL_DIR/greenbone-feed-sync/* /

# install gvm-tools
RUN mkdir -p $INSTALL_DIR/gvm-tools ;\
    python3 -m pip install --root=$INSTALL_DIR/gvm-tools --no-warn-script-location gvm-tools ;\
    rsync -Ka $INSTALL_DIR/gvm-tools/* /

# create gvm user
RUN useradd -r -M -U -G sudo -s /usr/sbin/nologin gvm

# add the ospd openvas conf from the local directory
COPY ospd-openvas.conf /etc/gvm/ospd-openvas.conf

# add the redis conf to redis
RUN cp $SOURCE_DIR/openvas-scanner-$OPENVAS_SCANNER_VERSION/config/redis-openvas.conf /etc/redis/ ;\
    chown redis:redis /etc/redis/redis-openvas.conf ;\
    echo "db_address = /run/redis-openvas/redis.sock" | tee -a /etc/openvas/openvas.conf ;\
    usermod -aG redis gvm

# restart the redis server
RUN service redis-server start /etc/redis/redis-openvas.conf

# copy the mosquitto config
COPY mosquitto.conf /etc/mosquitto.conf

# add the openvas-scanner config to the MQTT provider
RUN service mosquitto start ;\
    echo "mqtt_server_uri = localhost:1883"  | tee -a /etc/openvas/openvas.conf ;\
    echo "table_driven_lsc = yes" | tee -a /etc/openvas/openvas.conf

# refresh kernel modules
RUN ldconfig

# handle postgres creation
RUN apt-get install -y postgresql-15

USER postgres
RUN service postgresql start ;\
    createuser -DR root ;\
    createdb -O root gvmd ;\
    psql gvmd -c "create role dba with superuser noinherit; grant dba to root;" ;\
    psql gvmd -c "create extension \"uuid-ossp\";" ;\
    psql gvmd -c "create extension \"pgcrypto\";" ;\
    psql gvmd -c "create extension \"pg-gvm\";" ;\
    echo "local all all trust" > /etc/postgresql/15/main/pg_hba.conf

USER root

# refresh kernel modules
RUN ldconfig

# set correct permissions for gvm and create run directories to prevent claims of non-existance
RUN mkdir -p /var/lib/notus ;\
    mkdir -p /run/gvmd ;\
    mkdir -p /run/redis-openvas ;\
    mkdir -p /run/ospd ;\
    mkdir -p /run/mosquitto ;\
    chown -R gvm:gvm /var/lib/gvm ;\
    chown -R gvm:gvm /var/lib/openvas ;\
    chown -R gvm:gvm /var/lib/notus ;\
    chown -R gvm:gvm /var/log/gvm ;\
    chown -R gvm:gvm /run/gvmd ;\
    chmod -R g+srw /var/lib/gvm ;\
    chmod -R g+srw /var/lib/openvas ;\
    chmod -R g+srw /var/log/gvm ;\
    chmod -R g+srw /var/log/gvm

# perform GnuPG feed validation keychain
RUN curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc ;\
    mkdir -p ${GNUPGHOME} ;\
    gpg --import /tmp.GBCommunitySigningKey.asc ;\
    echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust ;\
    mkdir -p ${OPENVAS_GNUPG_HOME} ;\
    cp -r /tmp/openvas-gnupg/* ${OPENVAS_GNUPG_HOME}/ ;\
    chown -R gvm:gvm ${OPENVAS_GNUPG_HOME}

# start the sql server
# await sql server coming online before continuing
RUN if ! pg_isready > /dev/null 2>&1; then \
        service postgresql start && \
        while ! pg_isready > /dev/null 2>&1; do \
            echo "Awaiting postgres server to come online." && sleep 1; \
        done; \
    fi ;\
    /usr/local/sbin/gvmd --migrate && \
    /usr/local/sbin/gvmd --create-user=admin --password=${GVM_ADMIN_PASSWORD} && \
    /usr/local/sbin/gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value `/usr/local/sbin/gvmd --get-users --verbose | grep admin | awk '{print $2}'`

# cp service files to build dir
COPY ospd-openvas.service ${BUILD_DIR}/ospd-openvas.service
COPY notus-scanner.service ${BUILD_DIR}/notus-scanner.service
COPY gvmd.service ${BUILD_DIR}/gvmd.service
COPY gsad.service ${BUILD_DIR}/gsad.service

# cp built services
RUN cp -v $BUILD_DIR/ospd-openvas.service /etc/systemd/system/ ;\
    cp -v $BUILD_DIR/notus-scanner.service /etc/systemd/system/ ;\
    cp -v $BUILD_DIR/gvmd.service /etc/systemd/system/ ;\
    cp -v $BUILD_DIR/gsad.service /etc/systemd/system/

# run greenbone-feed-sync
# note: the following build step could take 20 minutes +. Please be patient. See README.md for more details
USER gvm
RUN /usr/local/bin/greenbone-feed-sync

# supply execute permissions to the entrypoint
USER root

# copy entrypoint to home
COPY entrypoint.sh /

# make entrypoint executable
RUN chmod +x /entrypoint.sh

# provision feed if set to build (otherwise this will be done on container initialisation [DEFAULT])
# note: the following build step could take 20 minutes +. Please be patient. See README.md for more details
RUN if [ "${FEED_PROVISION}" = "build" ]; then \
    sh /entrypoint.sh && until [ $(psql gvmd -t -c "SELECT COUNT(*) FROM nvts;") -gt 0 ]; do \
        echo `date +"%T"` Awaiting NVT Population and System Initialisation. Checking again in 5 seconds. && sleep 5; \
    done; fi;

# set CMD to entrypoint
CMD /entrypoint.sh && tail -f /var/log/gvm/gvmd.log
EXPOSE 80 5432