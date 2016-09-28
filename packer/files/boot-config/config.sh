#!/bin/sh

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

projects="p1"
services="git"

# Stop and remove docker instances and networks
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker network rm (docker network ls -q) || true

# Remove any autofs configuration
rm /etc/auto.master.d/*

# Create main subnetwork
docker network create --subnet=172.101.0.0/16 immut-net

# Create empty haproxy configuration file
HAPROXYDIR="/var/lib/immut-haproxy/"
HAPROXYCONF="$HAPROXYDIR/haproxy.cfg"
mkdir -p "$HAPROXYCONF"
cp "$SCRIPTPATH"/haproxy.cfg "$HAPROXYCONF"

for i in $projects; do
    for j in $services; do
        # Create autofs configuration file
        mkdir -p /var/data/$i/$j
        echo "/var/lib/immut/$i/$j -rw,soft :/var/data/$i/$j" >> /etc/auto.master.d/auto.$i

        # Update haproxy configuration
        echo "    acl host_$i_$j hdr(host) -m beg -i $j.$i" >> "$HAPROXYCONF"
        echo "    use_backend $i_$j_http if host_$i_$j" >> "$HAPROXYCONF"
        echo >> "$HAPROXYCONF"
    done
done

ip=3
for i in $projects; do
    for j in $services; do
        # Launch container
        docker run -d -v=/dev/log:/dev/log --net immut-net \
                   --ip 172.101.0.$ip \
                   -v=/var/lib/immut/$i/$j:/data:rw \
                   -v=/var/lib/sss/pipes/:/var/lib/sss/pipes/:rw \
                   $j # Service name has to match docker image name

        # Update haproxy with IP
        echo "backend $i_$j_http" >> "$HAPROXYCONF"
        echo "    server $i_$j 172.101.0.$ip:80" >> "$HAPROXYCONF"
        echo >> "$HAPROXYCONF"

        ip=$(expr $ip + 1)
    done
done

docker run -d -p 80:80 -p 443:443 -v=/dev/log:/dev/log \
           --net immut-net --ip 172.101.0.2 \
           -v=/var/lib/sss/pipes/:/var/lib/sss/pipes/:rw \
           -v=$HAPROXYDIR:/etc/haproxy/:rw \
           haproxy
