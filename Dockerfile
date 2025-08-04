# Copyright (C) Kakao Corp. All rights reserved.
# Copyright (C) 2017-2025 The ORT Project Authors (see <https://github.com/oss-review-toolkit/ort/blob/main/NOTICE>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
# License-Filename: LICENSE

FROM eclipse-temurin:17-jdk-jammy as base

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV GRADLE_VERSION=8.13
ENV GRADLE_VERSION_7_6_4=7.6.4
ENV ORT_VERSION=34.0.0
ENV CLI_VERSION=v2.7.0
ENV OPENJDK11_VERSION=11.0.16_8

ENV SBT_VERSION=1.10.0
ENV RUST_VERSION=1.72.0
ENV BOWER_VERSION=1.8.14
ENV NODEJS_VERSION=20.14.0
ENV NPM_VERSION=10.8.3
ENV PNPM_VERSION=9.9.0
ENV YARN_VERSION=1.22.19
ENV COCOAPODS_VERSION=1.15.2
ENV RUBY_VERSION=3.3.5
ENV DART_VERSION=2.18.4
ENV FLUTTER_VERSION=3.24.4

ENV PYTHON_VERSION=3.11.10
ENV PYENV_GIT_TAG=v2.4.13
ENV CONAN_VERSION=1.64.1
ENV PYTHON_INSPECTOR_VERSION=0.10.0
ENV PYTHON_PIPENV_VERSION=2023.12.1
ENV PYTHON_POETRY_VERSION=1.8.3
ENV PYTHON_SETUPTOOLS_VERSION=74.1.3
ENV PIPTOOL_VERSION=24.0
ENV SCANCODE_VERSION=32.2.1
ENV PHP_VERSION=8.3
ENV COMPOSER_VERSION=2.8.8

# Base package set
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    coreutils \
    curl \
    dirmngr \
    file \
    gcc \
    git \
    git-lfs \
    g++ \
    gnupg2 \
    iproute2 \
    libarchive-tools \
    libffi-dev \
    libgmp-dev \
    libmagic1 \
    libz-dev \
    locales \
    lzma \
    make \
    netbase \
    openssh-client \
    openssl \
    procps \
    rsync \
    sudo \
    tzdata \
    uuid-dev \
    unzip \
    wget \
    xz-utils \
    php \
    php-cli \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

RUN dpkg-reconfigure -f noninteractive tzdata

ARG USERNAME=deploy
ARG USER_ID=1001
ARG USER_GID=$USER_ID
ARG HOMEDIR=/home/deploy
ENV HOME=$HOMEDIR
ENV USER=$USERNAME

# Non privileged user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd \
    --uid $USER_ID \
    --gid $USER_GID \
    --shell /bin/bash \
    --home-dir $HOMEDIR \
    --create-home $USERNAME

RUN chgrp $USER /opt \
    && chmod g+wx /opt

# sudo support
RUN echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USER
WORKDIR $HOME

ENTRYPOINT [ "/bin/bash" ]
#------------------------------------------------------------------------
# PYTHON - Build Python as a separate component with pyenv
FROM base AS pythonbuild

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends \
    libreadline-dev \
    libgdbm-dev \
    libsqlite3-dev \
    libssl-dev \
    libbz2-dev \
    liblzma-dev \
    tk-dev \
    && sudo rm -rf /var/lib/apt/lists/*

ENV PYENV_ROOT=/opt/python
ENV PATH=$PATH:$PYENV_ROOT/shims:$PYENV_ROOT/bin
RUN curl -kSs https://pyenv.run | bash \
    && pyenv install -v $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION

RUN ARCH=$(arch | sed s/aarch64/arm64/) \
    &&  if [ "$ARCH" == "arm64" ]; then \
    pip install -U scancode-toolkit-mini==$SCANCODE_VERSION; \
    else \
    curl -Os https://raw.githubusercontent.com/nexB/scancode-toolkit/v$SCANCODE_VERSION/requirements.txt; \
    pip install -U --constraint requirements.txt scancode-toolkit==$SCANCODE_VERSION; \
    rm requirements.txt; \
    fi

RUN pip install --no-cache-dir -U \
    pip=="$PIPTOOL_VERSION" \
    wheel \
    && pip install --no-cache-dir -U \
    Mercurial \
    conan=="$CONAN_VERSION" \
    pipenv=="$PYTHON_PIPENV_VERSION" \
    poetry=="$PYTHON_POETRY_VERSION" \
    python-inspector=="$PYTHON_INSPECTOR_VERSION" \
    setuptools=="$PYTHON_SETUPTOOLS_VERSION"

FROM scratch AS python
COPY --from=pythonbuild /opt/python /opt/python

#------------------------------------------------------------------------
# NODEJS - Build NodeJS as a separate component with nvm
FROM base AS nodejsbuild

ENV NVM_DIR=/opt/nvm
ENV PATH=$PATH:$NVM_DIR/versions/node/v$NODEJS_VERSION/bin

RUN git clone --depth 1 https://github.com/nvm-sh/nvm.git $NVM_DIR
RUN . $NVM_DIR/nvm.sh \
    && nvm install "$NODEJS_VERSION" \
    && nvm alias default "$NODEJS_VERSION" \
    && nvm use default \
    && npm install --global npm@$NPM_VERSION bower@$BOWER_VERSION pnpm@$PNPM_VERSION yarn@$YARN_VERSION

FROM scratch AS nodejs
COPY --from=nodejsbuild /opt/nvm /opt/nvm

#------------------------------------------------------------------------
# RUBY - Build Ruby as a separate component with rbenv
FROM base AS rubybuild

# hadolint ignore=DL3004
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends \
    libreadline6-dev \
    libssl-dev \
    libz-dev \
    libffi-dev \
    libyaml-dev \
    make \
    xvfb \
    zlib1g-dev \
    && sudo rm -rf /var/lib/apt/lists/*

ENV RBENV_ROOT=/opt/rbenv
ENV PATH=$RBENV_ROOT/bin:$RBENV_ROOT/shims/:$RBENV_ROOT/plugins/ruby-build/bin:$PATH

RUN git clone --depth 1 https://github.com/rbenv/rbenv.git $RBENV_ROOT
RUN git clone --depth 1 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
WORKDIR $RBENV_ROOT
RUN src/configure \
    && make -C src
RUN rbenv install $RUBY_VERSION -v \
    && rbenv global $RUBY_VERSION \
    && gem install bundler cocoapods:$COCOAPODS_VERSION

FROM scratch AS ruby
COPY --from=rubybuild /opt/rbenv /opt/rbenv

#------------------------------------------------------------------------
# RUST - Build as a separate component
FROM base AS rustbuild

ENV RUST_HOME=/opt/rust
ENV CARGO_HOME=$RUST_HOME/cargo
ENV RUSTUP_HOME=$RUST_HOME/rustup
RUN curl -ksSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain $RUST_VERSION

FROM scratch AS rust
COPY --from=rustbuild /opt/rust /opt/rust

#------------------------------------------------------------------------
#  Dart
FROM base AS dartbuild

WORKDIR /opt/

ENV DART_SDK=/opt/dart-sdk
ENV PATH=$PATH:$DART_SDK/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN --mount=type=tmpfs,target=/dart \
    ARCH=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/x64/) \
    && curl -o /opt/dart.zip -L https://storage.googleapis.com/dart-archive/channels/stable/release/$DART_VERSION/sdk/dartsdk-linux-$ARCH-release.zip \
    && unzip /opt/dart.zip

FROM scratch AS dart
COPY --from=dartbuild /opt/dart-sdk /opt/dart-sdk

#------------------------------------------------------------------------
# ANDROID SDK
FROM base AS androidbuild

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends \
    unzip \
    && sudo rm -rf /var/lib/apt/lists/*

ARG ANDROID_CMD_VERSION=11076708
ENV ANDROID_HOME=/opt/android-sdk

RUN mkdir -p /tmp/android \
    && cd /tmp/android \
    && curl -Os https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMD_VERSION}_latest.zip \
    && unzip -q commandlinetools-linux-${ANDROID_CMD_VERSION}_latest.zip -d $ANDROID_HOME \
    && yes | $ANDROID_HOME/cmdline-tools/bin/sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "cmdline-tools;latest" \
    && rm -rf /tmp/android

RUN curl -ksS https://storage.googleapis.com/git-repo-downloads/repo > $ANDROID_HOME/cmdline-tools/bin/repo \
    && sudo chmod a+x $ANDROID_HOME/cmdline-tools/bin/repo

FROM scratch AS android
COPY --from=androidbuild /opt/android-sdk /opt/android-sdk

##------------------------------------------------------------------------
## SBT
FROM base AS scalabuild

ENV SBT_HOME=/opt/sbt
ENV PATH=$PATH:$SBT_HOME/bin

RUN curl -L https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz | tar -C /opt -xz

FROM scratch AS scala
COPY --from=scalabuild /opt/sbt /opt/sbt

#------------------------------------------------------------------------
# FLUTTER
FROM base AS flutterbuild

WORKDIR /opt/

ENV FLUTTER_SDK=/opt/flutter
ENV PATH=$PATH:$FLUTTER_SDK/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -o /opt/flutter.zip -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$FLUTTER_VERSION-stable.tar.xz \
    && tar -xvf /opt/flutter.zip

FROM scratch AS flutter
COPY --from=flutterbuild /opt/flutter /opt/flutter

#------------------------------------------------------------------------
# ORT
FROM base as ortbuild

ENV ort_release_url=https://github.com/oss-review-toolkit/ort/releases/download/$ORT_VERSION/ort-$ORT_VERSION.tgz
RUN curl -L ${ort_release_url} -o ort.tar.gz
RUN tar -zxvf ort.tar.gz \
    && chmod +x ort-$ORT_VERSION/bin/ort \
    && mv ort-$ORT_VERSION /opt/ort \
    && rm ort.tar.gz

FROM scratch AS ortbin
COPY --from=ortbuild /opt/ort /opt/ort
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# OLIVE CLI
FROM base as clibuild

ENV olivecli_release_url=https://github.com/kakao/olive-cli/releases/download/$CLI_VERSION/olive-cli-Linux-$CLI_VERSION-X64.tar.gz
RUN curl -L ${olivecli_release_url} -o olive-cli.tar.gz \
    && tar -zxvf olive-cli.tar.gz \
    && mkdir -p /opt/olivecli \
    && mv olive-cli /opt/olivecli/ \
    && chmod +x /opt/olivecli/olive-cli \
    && rm -rf olive-cli.tar.gz

FROM scratch AS oliveclibin
COPY --from=clibuild /opt/olivecli /opt/olivecli
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# Gradle 8
FROM base as gradlebuild

RUN curl -k -L -v -X GET https\://services.gradle.org/distributions/gradle-$GRADLE_VERSION-all.zip > gradle-$GRADLE_VERSION-all.zip
RUN unzip gradle-$GRADLE_VERSION-all.zip
RUN mv gradle-$GRADLE_VERSION /opt/gradle \
    && rm gradle-$GRADLE_VERSION-all.zip
RUN chmod +x /opt/gradle/bin/gradle

FROM scratch AS gradlebin
COPY --from=gradlebuild /opt/gradle /opt/gradle
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# Gradle 7.6.4
FROM base as gradle764build

RUN curl -k -L -v -X GET https\://services.gradle.org/distributions/gradle-$GRADLE_VERSION_7_6_4-all.zip > gradle-$GRADLE_VERSION_7_6_4-all.zip
RUN unzip gradle-$GRADLE_VERSION_7_6_4-all.zip
RUN mv gradle-$GRADLE_VERSION_7_6_4 /opt/gradle \
    && rm gradle-$GRADLE_VERSION_7_6_4-all.zip
RUN sudo chmod +x /opt/gradle/bin/gradle

FROM scratch AS gradle764bin
COPY --from=gradle764build /opt/gradle /opt/gradle
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# OpenJDK 11
FROM base as openjdk11build

RUN curl -L https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.16%2B8/OpenJDK11U-jdk_x64_linux_hotspot_11.0.16_8.tar.gz > openjdk-11.tar.gz \
    && tar -xzf openjdk-11.tar.gz \
    && mv jdk-11.0.16+8 /opt/openjdk-11 \
    && rm openjdk-11.tar.gz

FROM scratch AS openjdk11bin
COPY --from=openjdk11build /opt/openjdk-11 /opt/openjdk-11
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# Container with minimal selection of supported package managers.
FROM base

# Remove ort build scripts
RUN sudo rm -rf /etc/scripts

RUN sudo mkdir /kakao \
    && sudo mkdir /kakao/program \
    && sudo mkdir /kakao/repository \
    && sudo chown -R $USER:$USER /kakao \
    && sudo chmod -R 755 /kakao \
    && sudo chmod 775 /kakao/repository \
    && mkdir -p $HOME/repository \
    && chmod 775 $HOME/repository

#  Install optional tool subversion for ORT analyzer
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update && \
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends \
    subversion \
    && sudo rm -rf /var/lib/apt/lists/*

# Python
ENV PYENV_ROOT=/opt/python
ENV PATH=$PATH:$PYENV_ROOT/shims:$PYENV_ROOT/bin
COPY --from=python --chown=$USER:$USER $PYENV_ROOT $PYENV_ROOT

# NodeJS
ENV NVM_DIR=/opt/nvm
ENV PATH=$PATH:$NVM_DIR/versions/node/v$NODEJS_VERSION/bin
COPY --from=nodejs --chown=$USER:$USER $NVM_DIR $NVM_DIR

# Rust
ENV RUST_HOME=/opt/rust
ENV CARGO_HOME=$RUST_HOME/cargo
ENV RUSTUP_HOME=$RUST_HOME/rustup
ENV PATH=$PATH:$CARGO_HOME/bin:$RUSTUP_HOME/bin
COPY --from=rust --chown=$USER:$USER $RUST_HOME $RUST_HOME
RUN chmod o+rwx $CARGO_HOME

# Ruby
ENV RBENV_ROOT=/opt/rbenv/
ENV GEM_HOME=/var/tmp/gem
ENV PATH=$PATH:$RBENV_ROOT/bin:$RBENV_ROOT/shims:$RBENV_ROOT/plugins/ruby-install/bin
COPY --from=ruby --chown=$USER:$USER $RBENV_ROOT $RBENV_ROOT

# Scala
ENV SBT_HOME=/opt/sbt
ENV PATH=$PATH:$SBT_HOME/bin
COPY --from=scala --chown=$USER:$USER $SBT_HOME $SBT_HOME

# Dart
ENV DART_SDK=/opt/dart-sdk
ENV PATH=$PATH:$DART_SDK/bin
COPY --from=dart --chown=$USER:$USER $DART_SDK $DART_SDK

# FLUTTER install
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin
COPY --from=flutter --chown=$USER:$USER $FLUTTER_HOME $FLUTTER_HOME

# Android SDK install
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_USER_HOME=$HOME/.android
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/cmdline-tools/bin
ENV PATH=$PATH:$ANDROID_HOME/platform-tools
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin

COPY --from=android --chown=$USER:$USER $ANDROID_HOME $ANDROID_HOME
RUN sudo chmod -R o+rw $ANDROID_HOME

# GRADLE install
ENV GRADLE_HOME=/opt/gradle
ENV GRADLE_USER_HOME=$HOME/.gradle
RUN mkdir -p $GRADLE_HOME
COPY --from=gradlebin --chown=$USER:$USER /opt/gradle $GRADLE_HOME
ENV PATH=$PATH:$GRADLE_HOME/bin

# GRADLE 7 install
ENV GRADLE_7_HOME=/kakao/program/gradle
RUN sudo mkdir -p $GRADLE_7_HOME
COPY --from=gradle764bin --chown=$USER:$USER /opt/gradle $GRADLE_7_HOME
ENV PATH=$PATH:$GRADLE_7_HOME/bin

RUN mkdir $HOME/.gradle
COPY gradle.properties $HOME/.gradle/gradle.properties
RUN sudo chown $USER:$USER $HOME/.gradle/gradle.properties

# OpenJDK 11 install
ENV JAVA_11_HOME=/opt/openjdk-11
RUN mkdir -p $JAVA_11_HOME
COPY --from=openjdk11bin --chown=$USER:$USER /opt/openjdk-11 $JAVA_11_HOME

# PHP install
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt-get update \
    && sudo apt-get install -y software-properties-common \
    && sudo add-apt-repository ppa:ondrej/php \
    && sudo apt-get update \
    && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends php${PHP_VERSION} \
    && sudo rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/php/bin \
    && curl -ksS https://getcomposer.org/installer | php -- --install-dir=/opt/php/bin --filename=composer --$COMPOSER_VERSION

ENV PATH=$PATH:/opt/php/bin

# ORT install
ENV ORT_HOME=$HOME/.olive/packages/ort
RUN mkdir -p $HOME/.olive/packages
COPY --from=ortbin --chown=$USER:$USER /opt/ort $ORT_HOME
ENV PATH=$PATH:$ORT_HOME/bin

# OLIVE CLI install
ENV OLIVE_CLI_HOME=/kakao/program/olive-cli
RUN sudo mkdir -p ${OLIVE_CLI_HOME}
COPY --from=oliveclibin --chown=$USER:$USER /opt/olivecli/ ${OLIVE_CLI_HOME}/
ENV PATH=$PATH:$OLIVE_CLI_HOME

USER $USER
WORKDIR $HOME

ENTRYPOINT []
CMD ["/bin/bash"]