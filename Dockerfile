# first stage use pre build venv image to compile LedFx
FROM spirocekano/ledfx-virt:venv as compile-image

RUN /LedFx/venv/bin/pip install -U ledfx==0.10.1

# Create python:3.9-slim image
# This image copies /LedFx/venv from compile-image for a smaller final image

############### BUILD IMAGE ###############
FROM python:3.9-slim-buster

RUN set -ex \
    && apt-get update  \
    && apt-get install -y --no-install-recommends avahi-daemon \
    libnss-mdns \
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

# Copies /LedFx/venv from compile-image
COPY --from=compile-image /LedFx/venv/ /LedFx/venv/
COPY pulseaudio.client.conf /etc/pulse/client.conf
COPY asound.conf /etc/asound.conf
RUN useradd -l --create-home ledfx
# Set /LedFx/venv/bin to $PATH
ENV PATH="/LedFx/venv/bin:$PATH"
RUN adduser ledfx pulse-access
WORKDIR /home/ledfx
COPY setup-files/ /home/ledfx
RUN chmod a+wrx /home/ledfx/*.sh
USER ledfx
EXPOSE 8888
ENTRYPOINT ./entrypoint.sh