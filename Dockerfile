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

# 容器内是 root，挂载进来的宿主机文件属主不同，git 会报 dubious ownership。
# 用通配是因为每个 submodule 目录都要单独豁免。
RUN git config --global --add safe.directory '*'

# 主题以 submodule 引入，且 compose 会把宿主机目录挂到 /app 覆盖镜像内容，
# 所以必须在启动时初始化，构建时做会被挂载盖掉。
CMD git submodule update --init --recursive && hugo server --bind 0.0.0.0 -D --disableFastRender

