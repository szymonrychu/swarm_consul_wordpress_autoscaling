FROM alpine:3.8

ENV CONSUL_TEMPLATE_VERSION=0.19.5

ADD https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_SHA256SUMS /tmp/
ADD https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip /tmp/
ADD https://download.docker.com/linux/static/stable/x86_64/docker-18.06.0-ce.tgz /tmp/

RUN cd /tmp && \ 
    sha256sum -c consul-template_${CONSUL_TEMPLATE_VERSION}_SHA256SUMS 2>&1 | grep OK && \
    unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \ 
    mv consul-template /bin/consul-template && \
    tar -xzvf docker-18.06.0-ce.tgz -C / && \
    rm -rf /tmp

ENTRYPOINT ["/bin/consul-template"]