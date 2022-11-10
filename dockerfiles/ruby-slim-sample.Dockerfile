# this is a copy of the solidus_demo Dockerfile
# unfortunately, the image is quite big (1.7GB when built on that repo)

# TODO: use multi-stage build to lessen the size

ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-slim-buster

ARG PG_VERSION
ARG NODE_VERSION
ARG BUNDLER_VERSION

RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    git \
    imagemagick \
    chromium \
    shared-mime-info \
    nano \
  && rm -rf /var/cache/apt/lists/*

RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' $PG_VERSION > /etc/apt/sources.list.d/pgdg.list

RUN curl -sSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev \
    postgresql-client-$PG_VERSION \
    nodejs \
  &&  rm -rf /var/lib/apt/lists/*

ENV APP_USER=solidus_demo_user \
    LANG=C.UTF-8 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3
ENV GEM_HOME=/home/$APP_USER/gems
ENV APP_HOME=/home/$APP_USER/app
ENV PATH=$PATH:$GEM_HOME/bin

RUN gem update --system \
  && gem install bundler:$BUNDLER_VERSION 

RUN mkdir -p /home/$APP_USER/history

COPY Gemfile* package.json yarn.lock /home/$APP_USER/app/
WORKDIR /home/$APP_USER/app

RUN bundle install

COPY . /home/$APP_USER/app

RUN bundle check || bundle

RUN SECRET_KEY_BASE=1 bin/rails assets:precompile

ENTRYPOINT [ "./docker-entrypoint.sh" ]

CMD ["/bin/bash", "-c", "bin/rails server -b 0.0.0.0 -p 3000"]
