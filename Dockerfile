FROM debian:stable
ENV DEBIAN_FRONTEND noninteractive

# Base stuff
RUN apt update && apt install daemontools git locales wget -y
RUN sed -i 's/# en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen && locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US
ENV LC_ALL en_US.UTF-8

# qBittorrent
RUN apt install qbittorrent-nox -y && mkdir -p /downloads
COPY qBittorrent.conf /root/.config/qBittorrent/qBittorrent.conf
RUN mkdir -p /etc/service/qbittorrent && echo '#!/bin/bash\nqbittorrent-nox' | tee /etc/service/qbittorrent/run && chmod 755 /etc/service/qbittorrent/run

# Library management script
RUN wget -O /tmp/filebot.deb 'https://app.filebot.net/download.php?type=deb&arch=amd64' && apt install ffmpeg file openjdk-8-jre /tmp/filebot.deb -y; rm -f /tmp/filebot.deb
COPY add_to_library.sh /usr/local/bin/add_to_library.sh
RUN chmod 755 /usr/local/bin/add_to_library.sh

# goBrowser
RUN git clone https://github.com/xataz/gobrowser.git /opt/gobrowser && apt install golang -y && sed -i '/Content-Disposition/d' /opt/gobrowser/app.go && sed -i 's/>Download<\/a>/download target="_blank">Download<\/a>/g' /opt/gobrowser/templates/index.html && go build -o /opt/gobrowser/gobrowser /opt/gobrowser/app.go && mkdir -p /library/torrent || rm -rf /opt/gobrowser
RUN mkdir -p /etc/service/gobrowser && echo '#!/bin/bash\ncd /opt/gobrowser\n./gobrowser -listen 127.0.0.1:8080 -path /library' | tee /etc/service/gobrowser/run && chmod 755 /etc/service/gobrowser/run

# HAProxy
RUN apt install busybox-syslogd haproxy -y
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
RUN mkdir -p /etc/service/syslogd && echo '#!/bin/bash\nsyslogd -n -O /dev/stdout' | tee /etc/service/syslogd/run && chmod 755 /etc/service/syslogd/run
RUN mkdir -p /etc/service/haproxy && echo '#!/bin/bash\nhaproxy -f /etc/haproxy/haproxy.cfg' | tee /etc/service/haproxy/run && chmod 755 /etc/service/haproxy/run

# Container settings
ENTRYPOINT ["svscan", "/etc/service"]
VOLUME ["/downloads", "/library"]
EXPOSE 80 6881 6881/udp
