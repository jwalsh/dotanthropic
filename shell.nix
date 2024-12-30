{ pkgs ? import <nixpkgs> {} }:

let
  # Python environment with specific packages
  pythonEnv = pkgs.python311.withPackages (ps: with ps; [
    anthropic
    requests
    streamlit
    pip
    virtualenv
    psutil
    psycopg2
    watchdog
    boto3
    poetry-core
    tiktoken    # For token counting
    openai      # OpenAI API
  ]);

  # Custom shell hooks for direnv and other initializations
  shellHook = ''
    # Direnv setup
    eval "$(direnv hook bash)"
    
    # Enable bash completion
    source ${pkgs.bash-completion}/share/bash-completion/bash_completion
    
    # FZF key bindings and completion
    source ${pkgs.fzf}/share/fzf/key-bindings.bash
    source ${pkgs.fzf}/share/fzf/completion.bash
    
    # Set up locale
    export LANG="en_US.UTF-8"
    export LC_ALL="en_US.UTF-8"
    
    # Configure history
    export HISTSIZE=10000
    export HISTFILESIZE=20000
    export HISTCONTROL=ignoreboth:erasedups
    
    # Better default options for common tools
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    export RIPGREP_CONFIG_PATH="$PWD/.ripgreprc"
    
    # Useful aliases
    alias ll="ls -la"
    alias grep="rg"
    alias find="fd"
    alias cat="bat"
    
    # Ollama configuration
    export OLLAMA_HOST="localhost"
    export OLLAMA_PORT="11434"
    
    # Docker configuration for Anthropic computer use demo
    export DEMO_STREAMLIT_PORT="8501"
    export DEMO_VNC_PORT="5900"
    export DEMO_NOVNC_PORT="6080"
    export DEMO_API_PORT="8080"

    # Ensure directories exist
    mkdir -p $HOME/.anthropic/{tools,backups,journal,sandbox,docs}
    mkdir -p $HOME/.anthropic/journal/screenshots/$(date +%Y-%m-%d)
    
    # Set up environment marker
    export PS1="\n\[\033[1;35m\](dotanthropic)\[\033[0m\] \[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\] \$ "
    
    echo "🚀 Development environment loaded!"
  '';

in pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python environment
    pythonEnv
    poetry
    
    # Shell utilities and productivity tools
    direnv
    fzf
    ripgrep
    fd
    bat
    eza # Modern replacement for exa
    jq
    yq
    tree
    htop
    tmux
    watch
    shellcheck
    
    # Version control and collaboration
    git
    gh
    delta
    lazygit
    
    # Build tools and development
    gnumake
    cmake
    ninja
    pkg-config
    
    # Editors
    emacs
    neovim
    
    # Languages and runtimes
    rustc
    cargo
    clojure
    guile
    python3
    nodejs
    
    # System and network tools
    openssh
    openssl
    rsync
    curl
    wget
    netcat
    socat
    
    # Cloud and container tools
    docker
    docker-compose
    kubectl
    ollama
    
    # Database tools
    postgresql
    sqlite
    
    # Document processing
    mermaid-cli
    imagemagick
    ghostscript
    qrencode
    pandoc
    
    # System libraries and dependencies
    glibcLocales
    libyaml
    libxcrypt
    libiconv
    cacert
    gnupg
    
    # Additional shell tools
    bash
    bash-completion
    zsh
    coreutils
    gnused
    gawk
    
    # File management and navigation
    broot
    du-dust
    duf
    
    # Text processing
    sd
    choose
    xsv
  ];

  # Environment variables
  shellHook = shellHook;

  # SSL certificates configuration
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # PostgreSQL configuration
  PGDATA = "db";
  PGHOST = "127.0.0.1";
  PGPORT = "5432";
  
  # Rust configuration
  RUST_BACKTRACE = 1;
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
  
  # Ollama configuration
  OLLAMA_HOST = "localhost";
  OLLAMA_PORT = "11434";
  
  # Demo ports
  DEMO_STREAMLIT_PORT = "8501";
  DEMO_VNC_PORT = "5900";
  DEMO_NOVNC_PORT = "6080";
  DEMO_API_PORT = "8080";
  
  # Default AWS region
  AWS_REGION = "us-west-2";
  AWS_DEFAULT_REGION = "us-west-2";
  
  # Provider configuration
  PROVIDER = "bedrock";
}