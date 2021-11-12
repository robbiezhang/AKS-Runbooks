FROM ubuntu

RUN apt-get update \
    && apt-get install -y \
        traceroute \
        curl \
        dnsutils \
        netcat-openbsd \
        jq \
        nmap \ 
        net-tools \
        openssh-client \
        tcpdump \
        iptables \
    && rm -rf /var/lib/apt/lists/*

CMD [ "/bin/bash" ]

