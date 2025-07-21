FROM ghcr.io/runatlantis/atlantis:v0.27.2

USER root
RUN wget -O /tmp/conftest.tar.gz https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz \
    && tar -xzf /tmp/conftest.tar.gz -C /tmp \
    && mv /tmp/conftest /usr/local/bin/conftest \
    && chmod +x /usr/local/bin/conftest \
    && chown atlantis:atlantis /usr/local/bin/conftest \
    && rm /tmp/conftest.tar.gz

# Also ensure the atlantis bin directory has proper permissions
RUN mkdir -p /atlantis/bin/conftest/versions/0.46.0 \
    && cp /usr/local/bin/conftest /atlantis/bin/conftest/versions/0.46.0/conftest \
    && chmod +x /atlantis/bin/conftest/versions/0.46.0/conftest \
    && chown -R atlantis:atlantis /atlantis/bin

USER atlantis
RUN conftest --version
