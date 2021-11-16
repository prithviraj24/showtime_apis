# syntax = docker/dockerfile:1.2

ARG RUBY_VERSION=2.5.0

FROM ruby:$RUBY_VERSION


RUN adduser --home /home/showtime  --disabled-password --shell /bin/bash showtime
# set the app directory var
ENV APP_HOME /showtime
WORKDIR $APP_HOME

ARG PG_MAJOR=12.8
# ARG BUNDLER_VERSION=2.2.16
ARG NODE_MAJOR=15
ARG YARN_VERSION=1.22.5

ENV BUNDLER_VERSION=2.2.16
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_ENV development
ENV RAILS_ROOT=/app
ENV LANG=C.UTF-8
# ENV GEM_HOME=/bundle
# ENV BUNDLE_PATH=$GEM_HOME
# ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH
# ENV BUNDLE_BIN=$BUNDLE_PATH/bin
# ENV PATH=/app/bin:$BUNDLE_BIN:$PATH

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# Install essentials
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    curl \
    libpq-dev \
    git \
    ca-certificates \
    nodejs \
    yarn=$YARN_VERSION-1 \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log


# RUN apt-get update -qq \
#   && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
#     less \
#     libxml2-dev \
#     libgssapi-krb5-2 \
#     libpq5 \
#     libpam-dev \
#     libedit-dev \
#     libxslt1-dev \
#     nodejs \
#     yarn=$YARN_VERSION-1 \
#     git-core \
#     zlib1g-dev \
#     libssl-dev \
#     libreadline-dev \
#     libyaml-dev \
#     libcurl4-openssl-dev \
#     software-properties-common \
#     libffi-dev \
#     libgdbm-dev \
#     libncurses5-dev \
#     automake \
#     libtool \
#     bison \
#     gpg \
#   && apt-get clean \
#   && rm -rf /var/cache/apt/archives/* \
#   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
#   && truncate -s 0 /var/log/*log
  
# ENV PATH /app/bin:$PATH

# Install ruby dependencies
COPY Gemfile Gemfile.lock $APP_HOME/

# COPY Gemfile ./
RUN gem install bundler -v 2.2.16
# RUN bundler config default 2.2.16
ENV BUNDLER_WITHOUT development test
# RUN gem uninstall bundler -v 1.16.1
RUN gem list bundler
# RUN gem install bundler:2.2.16 \
RUN bundle install

COPY . $APP_HOME/

RUN chown -R showtime $APP_HOME $GEM_HOME
USER showtime
#RUN whoami
RUN bundle exec rake assets:precompile

CMD puma -C config/puma.rb
