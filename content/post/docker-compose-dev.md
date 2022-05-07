---
title: "Docker Compose Dev"
date: 2022-05-05T22:08:34+08:00
author: "xiantang"
# lastmod: 
# tags: []
# categories: []
# images:
#   - ./post/golang/cover.png
description:
draft: true
---


<!-- 
* 总是会先写一句话，同步背景和上下文
* 评论式写作引用一些大牛说的话
* 多一些有趣的跳转链接
* 在文章末尾推荐一些有趣的链接
* 先写提纲，再写内容 -->

> Docker 其实并不是一种新技术，而是一个新瓶装旧酒的工具。

其实我在大学上学的时候就用过 Docker，那个时候还是 17 年左右，Docker 还是如日中天的时候。只是用来起各种各样的轻量级应用，比如磁力链接下载器，个人网盘啥的。一直到不久的之前我对 Docker 的理解都还是比较模糊的，随着工作中需求的不断接触，我也不断的了解 Docker，于是打算写一篇文章总结一下最近对 Docker 的使用。

## 背景

其实是一直存在一个痛点就是，在我们的开发的时候有多个服务，并且服务之间是有相互的调用关系，但是如果是在本机中起来，服务总是可能会被各种端口占用，而且如果你的本机重启了，那么你的服务也会被关闭，是需要有一套好用的开发环境解决方案。

docker-compose 提供了将多个容器绑定起来的方式，可以很好的解决上述问题。

## 什么是 docker-compose

Compose 是一个用于定义和运行多容器 Docker 应用程序的工具。使用 Compose，您可以使用 YAML 文件来配置应用程序的服务。然后，使用一个命令，您可以从您的配置中创建并启动所有服务。

也就是只需要简单的一句 `docker-compose up` 就可以启动项目中所依赖的相关服务，例如数据库、缓存、微服务等。

## 一直没有玩好的困境

其实在很久之前我就有尝试用 `docker-compose` 来构建我的开发环境，但是遇到了一些让我觉得不舒服的点，不过随着对 `Docker` 的理解的不断深入，我也慢慢的会玩明白了。

### 难以排查问题

第一点就是上手 `Docker` 之后难以排查问题，排查问题主要是分成两点，难以排查构建镜像中失败的问题，第二点就是难以排查容器启动失败的问题。

容器构建失败是非常常见的事情：

比如见下面这个 Dockerfile

```
FROM python:3.6 AS builder

COPY requirements.txt ./
RUN python -m pip install -r requirements.txt  https://pypi.tuna.tsinghua.edu.cn/simple
```

就比如说倘若 `RUN python -m pip install -r requirements.txt  https://pypi.tuna.tsinghua.edu.cn/simple` 这个命令一直失败，那我们就可以 Dockerfile 改成上次成功的构建 + CMD[“bash”]

```
FROM python:3.6 AS builder

COPY requirements.txt ./
CMD ["bash"]
```

构建成功了之后，将这个容器使用直接起来，或者将 CMD 改写成 `bash`，就可以进入容器了，然后就可以看看到底是为什么 pip install 失败了。

docker run 命令是可以跟着参数将 CMD 改写的。

`docker run [OPTIONS] IMAGE [COMMAND] [ARG...]`
`docker run -ti  --rm  your_image  bash`

### 公司仓库的 private 库

工作中用 `Golang` 的时候经常会被各种私有库所挡住，比如 `Github`、`Gitlab`、`Gitee` 等。
其实这个很简单，就是当发现 `go mod download` 下不来的时候，可以尝试改写你的 COMMAND 然后进到容器中进行排查。

对于用来自己开发的 Dockerfile，其实可以使用 `.netrc` 的方式来解决这个问题。
参见这个回答：

`https://stackoverflow.com/questions/65824786/building-go-apps-with-private-gitlab-modules-in-docker`

### docker logs

如果想要查看容器的日志，可以使用 `docker logs` 命令，但是需要注意的是如果你的日志都是本地的 log 文件中，没有写到 `stdout` 的时候，使用 `docker logs` 是查不到问题的。

### 容器一起来就挂

很多时候你刚构建完成镜像，尝试 run 的时候，容器会一直退出，这个时候可以使用我上面提到的方法，把默认的 CMD 的命令改写成 bash，直接进去容器去跑一下你的命令，看看退出的日志就可以很轻松的查出问题了。

`docker run -ti  --rm  your_image  bash`

## 编写 compose 的配置文件

其实你可以把 `Docker` 的容器想的很简单，是一个普通操作系统的进程只不过有独立的网络，独立的文件系统，和自己单独的进程树。

所以在建设自己的微服务环境的时候，需要关注容器的网络是否是联通的，以及容器中的文件是否需要挂载到本地。

### 网络隔离

对于网络的联通，我们可以使甼 `docker network create --driver bridge your_network` 创建一个网络，然后把容器挂载到这个网络中。

docker compose 也可以定义网络，但是需要注意的是，如果你的网络是自己创建的，那么你需要在 `docker-compose.yml` 中指定网络的名称。

```
networks:
  your_network:
    driver: bridge
```

docker 是建议使用自己建立的网络，而不是使用默认的网络。


在这个 network 下的容器，docker 提供了 DNS lookup service。

```
  mysql:
    ... 
    networks:
      - your_network
  your_service:
    ...
    networks:
      - your_network
```

如果你的容器中有 ping，你就可以在 your_service 中使用 `ping mysql` 来检查是否能够 ping 过去。就是说可以通过用 `docker-compose` 中名字来访问到对应的容器。

也可以使用 `busybox` 来检查容器的网络是否联通。

`docker run -ti --rm  --network=your_network busybox sh`
