ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-slim

ENV LANG=C.UTF-8

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get -qq update \
 && apt-get -qq install -y --no-install-recommends build-essential curl jq \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG USER_ID
ARG GROUP_ID
RUN gem install bundler \
 && addgroup --gid ${GROUP_ID} app \
 && adduser --disabled-password --uid ${USER_ID} --ingroup app --gecos '' app

WORKDIR /home/app

COPY --chown=app:app Gemfile* ./

RUN bundle install

USER app

ENV PATH="/home/app/bin:${PATH}"

COPY --chown=app:app . ./
RUN chmod +x ./bin/*

CMD ["bundle", "exec", "puma", "-p", "3000"]
