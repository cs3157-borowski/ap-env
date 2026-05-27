# ap-course-env/Dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
LABEL org.opencontainers.image.source = "https://github.com/cs3157-borowski/ap-env"

# Basic dev tools for C
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        gdb \
        make \
        cmake \
        clang \
        clang-format \
        valgrind \
        git \
        vim \
        neovim \
        nano \
        btop \
        sudo \
        python3 \
        python3-pip \
        libc6-dev \
        # Documentation and man pages \
        man-db \
        manpages-dev \
        manpages-posix-dev \
        # Debugging and analysis tools \
        strace \
        ltrace \
        cppcheck \
        # Shell and text processing utilities \
        bash-completion \
        shellcheck \
        less \
        curl \
        wget \
        tree \
        bc \
        diffutils \
        patch \
        zip \
        unzip \
        # Additional build tools \
        autoconf \
        automake \
        libtool \
        pkg-config \
        # Other tools
        hyperfine \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user "student"
RUN useradd -ms /bin/bash student
USER student
WORKDIR /ap

# Nice colorful prompt
RUN echo 'export PS1="\[\033[1;32m\](ap-env)\[\033[0m\] \[\033[1;36m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]$ "' >> ~/.bashrc

# Reminder banner shown on every shell start
RUN printf '%s\n' \
    '' \
    'printf "\\033[1;33m\\n"' \
    'printf "  ╔══════════════════════════════════════════════════════════════════╗\\n"' \
    'printf "  ║                                                                  ║\\n"' \
    'printf "  ║                       !! IMPORTANT !!                            ║\\n"' \
    'printf "  ║                                                                  ║\\n"' \
    'printf "  ║   Always save your work inside /ap                               ║\\n"' \
    'printf "  ║                                                                  ║\\n"' \
    'printf "  ║   /ap is shared with your computer - files there are safe.       ║\\n"' \
    'printf "  ║   Files saved OUTSIDE /ap will be LOST if the container          ║\\n"' \
    'printf "  ║   is ever recreated (e.g., after a course image update).         ║\\n"' \
    'printf "  ║                                                                  ║\\n"' \
    'printf "  ╚══════════════════════════════════════════════════════════════════╝\\n"' \
    'printf "\\033[0m\\n"' \
    >> ~/.bashrc

CMD ["/bin/bash"]
