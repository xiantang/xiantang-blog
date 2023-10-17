FROM ubuntu:20.04 as build

RUN apt-get update && apt-get install -y git

ENV HUGO_VERSION 0.59.0
ENV HUGO_BINARY hugo_extended_${HUGO_VERSION}_Linux-64bit.deb

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} /tmp/hugo.deb
RUN dpkg -i /tmp/hugo.deb \
	&& rm /tmp/hugo.deb
#
WORKDIR /app

COPY . .
EXPOSE 1313

RUN git submodule init && git submodule update && git config --global --add safe.directory /app
CMD hugo server --bind 0.0.0.0 -D --disableFastRender

