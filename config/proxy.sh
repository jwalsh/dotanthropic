#!/bin/bash
export HTTP_PROXY="http://proxy:8080"
export HTTPS_PROXY="http://proxy:8080"
export NO_PROXY="localhost,127.0.0.1"
export REQUESTS_CA_BUNDLE="/usr/local/share/ca-certificates/mitmproxy-ca-cert.crt"
