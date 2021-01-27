FROM rcarmo/ubuntu-python

WORKDIR /app

RUN pip install Cython
RUN apt-get update

# https://gnanesh.me/avahi-docker-non-root.html
RUN set -ex \
 && apt-get update && apt-get install -y --no-install-recommends avahi-daemon libnss-mdns \
 # Allow hostnames with more labels to be resolved so that we can resolve node1.mycluster.local.
 # https://github.com/lathiat/nss-mdns#etcmdnsallow
 && echo '*' > /etc/mdns.allow \
 # Configure NSSwitch to use the mdns4 plugin so mdns.allow is respected
 && sed -i "s/hosts:.*/hosts:          files mdns4 dns/g" /etc/nsswitch.conf \
 && printf "[server]\nenable-dbus=no\n" >> /etc/avahi/avahi-daemon.conf \
 && chmod 777 /etc/avahi/avahi-daemon.conf \
 && mkdir -p /var/run/avahi-daemon \
 && chown avahi:avahi /var/run/avahi-daemon \
 && chmod 777 /var/run/avahi-daemon

RUN apt-get install -y gcc \
                       git \
                       libatlas3-base \
                       libatlas3-base \
                       portaudio19-dev \
                       pulseaudio
RUN pip install  --upgrade pip wheel setuptools
RUN pip install git+https://github.com/LedFx/LedFx

RUN apt-get install -y pulseaudio alsa-utils
RUN adduser root pulse-access

COPY setup-files/ /app/
RUN chmod a+wrx /app/*

ENTRYPOINT ./entrypoint.sh