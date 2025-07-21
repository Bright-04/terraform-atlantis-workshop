FROM ghcr.io/runatlantis/atlantis:latest

USER root
RUN wget -O /tmp/conftest.tar.gz https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz \
    && tar -xzf /tmp/conftest.tar.gz -C /tmp \
    && mv /tmp/conftest /usr/local/bin/conftest \
    && chmod +x /usr/local/bin/conftest \
    && rm /tmp/conftest.tar.gz

USER atlantis
RUN conftest --version
