ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}-slim-buster

ENV LANG=C.UTF-8

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get -qq update \
 && apt-get -qq install -y --no-install-recommends build-essential \
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

COPY --chown=app:app ./bin ./bin/
RUN chmod +x ./bin/*

CMD ["irb"]
