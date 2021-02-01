# first stage
# https://www.docker.com/blog/containerized-python-development-part-1/

FROM python:3.9-buster AS builder

RUN set -ex \
&& apt-get update  \
&& apt-get install -y --no-install-recommends \
                       gcc \
                       git \
                       libatlas3-base \
                       portaudio19-dev \
                       pulseaudio
# Install LedFx with pip’s --user option, all its files will be installed in the .local directory of the current user’s home directory. 
# That means all the files will end up in a single place for easily copy in sedond stage.

RUN pip install --user --no-cache git+https://github.com/LedFx/LedFx@Virtuals


# second stage 

FROM python:3.9-slim-buster

RUN set -ex \
&& apt-get update  \
&& apt-get install -y --no-install-recommends avahi-daemon libnss-mdns \
                       portaudio19-dev \
                       pulseaudio \
                       libavahi-client3 \
                       alsa-utils \
                       wget \ 
 # https://gnanesh.me/avahi-docker-non-root.html
 # Installing avahi-daemon to enable auto discovery on linux host if network_mode: host i pass to docker container                    
 # Allow hostnames with more labels to be resolved so that we can resolve node1.mycluster.local.
 # https://github.com/lathiat/nss-mdns#etcmdnsallow
 && echo '*' > /etc/mdns.allow \
 # Configure NSSwitch to use the mdns4 plugin so mdns.allow is respected
 && sed -i "s/hosts:.*/hosts:          files mdns4 dns/g" /etc/nsswitch.conf \
 && printf "[server]\nenable-dbus=no\n" >> /etc/avahi/avahi-daemon.conf \
 && chmod 777 /etc/avahi/avahi-daemon.conf \
 && mkdir -p /var/run/avahi-daemon \
 && chown avahi:avahi /var/run/avahi-daemon \
 && chmod 777 /var/run/avahi-daemon\                       
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

COPY --from=builder /root/.local /root/.local

ENV PATH=/root/.local/bin:$PATH
RUN adduser root pulse-access
WORKDIR /app
COPY setup-files/ /app/
RUN chmod a+wrx /app/*.sh
EXPOSE 8888
ENTRYPOINT ./entrypoint.sh
