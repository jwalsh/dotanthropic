#!/usr/bin/env bash

set -euxo pipefail

JOBS=`nproc --ignore=2`
EMACS_DIR="emacs"

# Handle Docker environment where USER might not be set
CURRENT_USER=${USER:-$(whoami)}

# Try to get latest code or use existing checkout
if [ ! -d "$EMACS_DIR" ]; then
    git clone git://git.sv.gnu.org/emacs.git "$EMACS_DIR"
else
    cd "$EMACS_DIR"
    git clean -fdx  # Clean up any failed builds
    
    # Fetch master and create a local branch if needed
    git fetch origin master
    
    # Check if master branch exists locally
    if git rev-parse --verify master >/dev/null 2>&1; then
        git checkout master
        git reset --hard origin/master
    else
        git checkout -b master origin/master
    fi
    cd ..
fi

pushd "$EMACS_DIR"

configure_mail() {
    sudo debconf-set-selections <<EOF
postfix postfix/mailname string defrecord.com
postfix postfix/main_mailer_type string 'Local only'
EOF

    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y postfix

    # Configure postfix without systemd
    sudo postconf -e "mydomain = defrecord.com"
    sudo postconf -e "myorigin = defrecord.com"
    sudo postconf -e "inet_interfaces = loopback-only"
    sudo postconf -e "mydestination = defrecord.com, localhost.defrecord.com, localhost"
    
    # Start postfix directly instead of using systemd
    sudo /etc/init.d/postfix start || true
}

# Create install directories with proper permissions
sudo mkdir -p /usr/local/share/info
sudo mkdir -p /usr/local/share/emacs
sudo mkdir -p /usr/local/bin
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} /usr/local/share/info
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} /usr/local/share/emacs
sudo chown -R ${CURRENT_USER}:${CURRENT_USER} /usr/local/bin

# Install dependencies including full image support
sudo apt update -y
sudo apt install -y build-essential \
    texinfo \
    libgnutls28-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff5-dev \
    libgif-dev \
    libxpm-dev \
    libncurses-dev \
    libgtk-3-dev \
    libtree-sitter-dev \
    gcc-11 \
    g++-11 \
    libgccjit0 \
    libgccjit-11-dev \
    autoconf \
    libjansson4 \
    libjansson-dev \
    librsvg2-dev \
    libwebp-dev \
    libheif-dev \
    libsqlite3-dev \
    libgpm-dev \
    libturbojpeg0-dev \
    libxml2-dev \
    libharfbuzz-dev \
    librsvg2-bin \
    libacl1-dev \
    libgmp-dev \
    libotf-dev \
    libselinux1-dev \
    zlib1g-dev \
    libmagickwand-dev \
    libmagickcore-dev \
    imagemagick-6.q16 \
    pkg-config

configure_mail

DEBIAN_FRONTEND=noninteractive sudo apt install -y mailutils

export CC=/usr/bin/gcc-11 CXX=/usr/bin/g++-11

# Clean up any previous build artifacts
# make distclean || true

./autogen.sh \
    && ./configure \
    --with-native-compilation \
    --with-pgtk \
    --with-x-toolkit=gtk3 \
    --with-tree-sitter \
    --with-wide-int \
    --with-json \
    --with-modules \
    --without-dbus \
    --with-gnutls \
    --with-mailutils \
    --without-pop \
    --with-cairo \
    --with-imagemagick \
    --with-jpeg \
    --with-png \
    --with-rsvg \
    --with-tiff \
    --with-webp \
    --with-xml2 \
    --with-harfbuzz \
    --with-zlib \
    --with-compress-install \
    --prefix=/usr/local \
    CFLAGS="-O2 -pipe -mtune=native -march=native -fomit-frame-pointer"

make -j${JOBS} NATIVE_FULL_AOT=1

# Use sudo for the install step
sudo make install

popd
