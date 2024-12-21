#!/bin/bash
# Proxy configuration for Anthropic environment
export HTTP_PROXY="http://host.docker.internal:8080"
export HTTPS_PROXY="http://host.docker.internal:8080"
export NO_PROXY="localhost,127.0.0.1"
export REQUESTS_CA_BUNDLE="/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"

# Additional environment variables for specific tools
export CURL_CA_BUNDLE="/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"
export NODE_EXTRA_CA_CERTS="/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"
export SSL_CERT_FILE="/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"
source /home/computeruse/.anthropic/config/java.sh
