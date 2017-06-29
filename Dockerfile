ARG ARCH

FROM astroswarm/base-$ARCH:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update
RUN apt-get -y install build-essential curl git
RUN apt-get -y install zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get -y install rbenv
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN CONFIGURE_OPTS="--disable-install-doc --enable-shared" rbenv install -v 2.4.1

ENV PATH $HOME/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN rbenv global 2.4.1
RUN rbenv exec gem install --no-ri --no-rdoc bundler

# Install Docker (needed to build docker-compose)
WORKDIR /tmp
# x86_64
RUN uname -a | grep x86_64 && curl -o docker-ce_17.06.0~ce-0~debian_amd64.deb https://download.docker.com/linux/debian/dists/jessie/pool/stable/amd64/docker-ce_17.06.0~ce-0~debian_amd64.deb || true
RUN uname -a | grep x86_64 && dpkg -i --triggers docker-ce_17.06.0~ce-0~debian_amd64.deb ; apt-get -fy install || true
# ARM
RUN uname -a | grep arm && curl -o docker-ce_17.06.0~ce-0~debian_armhf.deb https://download.docker.com/linux/debian/dists/jessie/pool/stable/armhf/docker-ce_17.06.0~ce-0~debian_armhf.deb || true
RUN uname -a | grep arm && dpkg -i docker-ce_17.06.0~ce-0~debian_armhf.deb ; apt-get -fy install || true
RUN apt-get -fy install

# Install docker-compose
WORKDIR /tmp
RUN curl -L --fail https://github.com/docker/compose/releases/download/1.14.0/run.sh > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

RUN curl -L -o 1.14.0.tar.gz https://github.com/docker/compose/archive/1.14.0.tar.gz
RUN tar xvfz 1.14.0.tar.gz
WORKDIR /tmp/compose-1.14.0
# Build on x86_64
RUN uname -a | grep x86_64 && docker build -f Dockerfile -t docker/compose:1.14.0 ./ || true
# Build on ARM
RUN uname -a | grep arm && docker build -f Dockerfile.armhf -t docker/compose:1.14.0 ./ || true

ENV INSTALL_PATH /app

RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

ENV BUNDLE_PATH /bundle

COPY Gemfile $INSTALL_PATH
COPY Gemfile.lock $INSTALL_PATH
RUN rbenv exec bundle install

COPY . $INSTALL_PATH

EXPOSE 9292

CMD rbenv exec bundle exec rackup -s puma -p 9292 -o 0.0.0.0 -E $RACK_ENV
