FROM fedora:24

COPY fedora-atomic-update-tree.json /home/fedora-atomic-update-tree.json

RUN dnf -y update \
&& dnf install -y rpm-ostree git nc \
&& dnf clean all

RUN mkdir -p /home/working \
&& cd /home/working \
&& git clone https://github.com/CentOS/sig-atomic-buildscripts \
&& git clone https://git.fedorahosted.org/git/fedora-atomic.git

RUN mkdir -p /srv/rpm-ostree/repo \
&& cd /srv/rpm-ostree/ \
&& ostree --repo=repo init --mode=archive-z2

RUN cd /home/working/fedora-atomic/ \
&& git fetch \
&& git checkout f23 \
&& curl -o fedora-23-updates.repo https://git.fedorahosted.org/cgit/fedora-repos.git/plain/fedora-updates.repo?h=f23 \
&& sed -i 's/$releasever/23/g' fedora-23-updates.repo

RUN mv /home/fedora-atomic-update-tree.json /home/working/fedora-atomic/fedora-atomic-update-tree.json
