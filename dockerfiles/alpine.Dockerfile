ARG RUBY_VERSION=2.6.6
ARG RAILS_ENV=production

# Ruby bundle - install bundler, gems
FROM ruby:$RUBY_VERSION-alpine AS ruby-bundle

ENV RAILS_ENV $RAILS_ENV
ENV BUNDLE_PATH /app/vendor/bundle
ENV MAKE make --jobs 8
ENV BUNDLE_RETRY 3
ENV BUNDLE_WITHOUT development:test
ENV BUNDLE_CLEAN true

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    alpine-sdk \
    tzdata \
    shared-mime-info \
    postgresql-client \
    postgresql-dev

COPY Gemfile Gemfile.lock .ruby-version /app/
WORKDIR /app

RUN gem install bundler:2.3.8
RUN bundle install && \
    rm -f /app/vendor/bundle/ruby/*/gems/*/ext/*.o # cleanup compilation artifacts

# javascript bundle - install node & dependencies
FROM node:16-alpine AS javascript-bundle

ENV NODE_ENV production

COPY package.json yarn.lock /app/
WORKDIR /app
RUN yarn install --frozen-lockfile

FROM ruby:$RUBY_VERSION-alpine AS base

WORKDIR /app

# Copy node files from javascript bundle
COPY --from=javascript-bundle /usr/lib /usr/lib
COPY --from=javascript-bundle /usr/local/share /usr/local/share
COPY --from=javascript-bundle /usr/local/lib /usr/local/lib
COPY --from=javascript-bundle /usr/local/include /usr/local/include
COPY --from=javascript-bundle /usr/local/bin /usr/local/bin

RUN apk update && \
    apk upgrade && \
    apk add --no-cache tzdata \
    postgresql-client file bash \
    redis gnupg imagemagick curl yarn && \
    gem install bundler:2.3.8 && \
    rm -rf /var/cache/apk/*

################################################################################

FROM base AS production

ENV LANG C.UTF-8
ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT true
ENV BUNDLE_PATH /app/vendor/bundle
ENV BUNDLE_WITHOUT development:test
ENV PORT 3000

COPY --from=ruby-bundle /app/vendor/bundle /app/vendor/bundle

COPY . /app

RUN bin/rails assets:precompile && \
    bin/rails assets:clean && \
    yarn cache clean --all && \
    rm -rf /app/tmp && \
    rm -rf /app/node_modules/.cache && \
    rm -rf /app/aws && \
    rm -rf /app/vendor/bundle/ruby/*/cache

EXPOSE 3000

ENTRYPOINT [ "./docker-entrypoint.sh" ]

CMD ["/bin/bash", "-c", "bin/rails server -b 0.0.0.0 -p 3000"]
