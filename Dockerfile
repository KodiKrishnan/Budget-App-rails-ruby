# Stage 1: Builder
FROM ruby:3.1.2-alpine AS builder

ARG RAILS_MASTER_KEY
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

# Install build dependencies
RUN apk add --no-cache build-base git postgresql-dev tzdata nodejs npm

WORKDIR /app

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set without 'development test' && bundle install --jobs=4

# Install JS packages
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy app code
COPY . .

# Precompile assets
RUN RAILS_ENV=production

# Stage 2: Runtime
FROM ruby:3.1.2-alpine

RUN apk add --no-cache libpq tzdata nodejs

WORKDIR /app

# Copy prebuilt gems and app code from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# Required ENV variables
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    PORT=3000

# Serve static files (set via .env)
ENV RAILS_SERVE_STATIC_FILES=true

EXPOSE $PORT

#CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
CMD bundle exec rails assets:precompile && bundle exec puma -C config/puma.rb
