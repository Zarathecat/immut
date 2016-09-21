FROM fedora:24

RUN dnf -y update
RUN dnf -y install haproxy
RUN dnf -y clean all


WORKDIR /haproxy
COPY haproxy.cfg /etc/haproxy/haproxy.cfg

# Configure port and program to start
EXPOSE 80
COPY start.sh start.sh
CMD ["sh", "start.sh"]
