---
title: "Using Docker Compose to Set Up Your Own Development Environment"
date: 2022-05-05T22:08:34+08:00
author: "xiantang"
# lastmod: 
tags: ["Docker"]
categories: ["Docker"]
images:
  - ./post/docker-compose-dev.png
description:
draft: false
---

<!-- 
* Always start with a sentence to synchronize the background and context
* Comment-style writing quotes some big cows
* More interesting jump links
* Recommend some interesting links at the end of the article
* Write the outline first, then the content -->

> Docker is not a new technology, but a tool that puts old wine in new bottles.

Actually, I used Docker when I was in college, around 2017, when Docker was in its heyday. It was just used to start various lightweight applications, such as magnetic link downloaders, personal network disks, etc. Until recently, my understanding of Docker was still relatively vague. As I continued to encounter requirements at work, I also continued to understand Docker, so I decided to write an article to summarize my recent use of Docker.

## Background

There has always been a pain point, that is, there are multiple services during our development, and there is a call relationship between the services, but if it is started on the local machine, the service may always be occupied by various ports, and if your local machine restarts, then your service will also be closed. There needs to be a good development environment solution.

docker-compose provides a way to bind multiple containers together, which can solve the above problems well.

## What is docker-compose

Compose is a tool for defining and running multi-container Docker applications. With Compose, you can use a YAML file to configure your application's services. Then, with a single command, you can create and start all services from your configuration.

That is, you only need a simple `docker-compose up` to start the related services that the project depends on, such as databases, caches, microservices, etc.

## The dilemma of not playing well

Actually, I tried to use `docker-compose` to build my development environment a long time ago, but I encountered some points that made me feel uncomfortable. However, as my understanding of `Docker` deepened, I gradually figured it out.

### Difficult to troubleshoot

The first point is that it is difficult to troubleshoot after getting started with `Docker`. Troubleshooting is mainly divided into two points. It is difficult to troubleshoot the problem of failure in building images. The second point is that it is difficult to troubleshoot the problem of container startup failure.

Container build failures are very common:

For example, see the Dockerfile below

```
FROM python:3.6 AS builder

COPY requirements.txt ./
RUN python -m pip install -r requirements.txt  https://pypi.tuna.tsinghua.edu.cn/simple
```

For instance, if the `RUN python -m pip install -r requirements.txt  https://pypi.tuna.tsinghua.edu.cn/simple` command keeps failing, we can change the Dockerfile to the last successful build + CMD["bash"]

```
FROM python:3.6 AS builder

COPY requirements.txt ./
CMD ["bash"]
```

After the build is successful, you can directly start this container, or rewrite CMD to `bash`, then you can enter the container, and then you can see why pip install failed.

The docker run command can follow parameters to rewrite CMD.

`docker run [OPTIONS] IMAGE [COMMAND] [ARG...]`
`docker run -ti  --rm  your_image  bash`

### Private libraries in the company repository

When using `Golang` at work, you often get blocked by various private libraries, such as `Github`, `Gitlab`, `Gitee`, etc.
Actually, this is very simple. When you find that `go mod download` cannot be downloaded, you can try to rewrite your COMMAND and then enter the container for troubleshooting.

For Dockerfile used for your own development, you can actually use the `.netrc` method to solve this problem.
See this answer:

`https://stackoverflow.com/questions/65824786/building-go-apps-with-private-gitlab-modules-in-docker`

### docker logs

If you want to view the logs of the container, you can use the `docker logs` command, but you need to note that if your logs are all in the local log file and are not written to `stdout`, you cannot find the problem with `docker logs`.

### The container hangs as soon as it comes up

Many times when you have just completed the image build and try to run it, the container will keep exiting. At this time, you can use the method I mentioned above, rewrite the default CMD command to bash, go directly into the container to run your command, and look at the exit logs. You can easily find out the problem.

`docker run -ti  --rm  your_image  bash`

## Writing the compose configuration file

Compose has two important concepts:

- **services**, this is a `map`, where the key is the name of the container, and the value is the configuration of the container.
- **projects**, a complete business unit composed of a set of associated application containers, defined in the docker-compose.yml file.

As you can see, a project can be associated with multiple services (containers), and Compose manages projects.

In fact, you can think of `Docker` containers very simply, they are just ordinary operating system processes, but they have independent networks, independent file systems, and their own separate process trees.

Therefore, when building your own microservice environment, you need to pay attention to whether the network of the container is connected, and whether the files in the container need to be mounted locally.

```
version: '3'
services:
  web:
    build: .
    ports:
     - "5000:5000"

  redis:
    image: "redis:alpine"
```

This is a very simple example, linking the web and redis services together, allowing the two containers to work in the same project.

### Network isolation

For network connectivity, we can create a network with `docker network create --driver bridge your_network`, and then mount the container to this network.

docker compose can also define networks, but what needs to be noted is that if your network is created by yourself, then you need to specify the name of the network in `docker-compose.yml`.

```
networks:
  your_network:
    driver: bridge
```

Docker recommends using your own established network, rather than using the default network.


For containers under this network, docker provides a DNS lookup service.

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

If your container has ping, you can use `ping mysql` in your_service to check if you can ping. That is, you can access the corresponding container by using the name in `docker-compose`.

You can also use `busybox` (a tiny version of many common [[UNIX]] utilities combined into a small executable file.) to check whether the container's network is connected.

`docker run -ti --rm  --network=your_network busybox sh`

## Common Best Practices

### Use multi-stage builds

By using multi-stage builds, only the last stage is used to build the image, resulting in a more streamlined image.

```
FROM python:3.6 
WORKDIR /APP

COPY . .
RUN python -m pip install -r requirements.txt  -i https://pypi.tuna.tsinghua.edu.cn/simple

CMD ["python","spider.py"]
```

It can be rewritten in the following format:

```
FROM python:3.6 AS builder

COPY requirements.txt ./
RUN python -m pip install -r requirements.txt  -i https://pypi.tuna.tsinghua.edu.cn/simple

FROM python:3.6-slim 

COPY --from=builder /usr/local/lib/python3.6/site-packages /usr/local/lib/python3.6/site-packages
WORKDIR /APP

COPY spider.csv ./
COPY *.py ./

CMD ["python","spider.py"]
```

### Adjust the order of Dockerfile

Adjust the order of Dockerfile. Because once a step changes, the cache of the following steps will be discarded. Therefore, it is better to put the larger changes at the end.

The following format is that when you change a line of code in a py file, every time docker build will discard the cache of the dependencies downloaded below, so it is better to put the larger changes at the end.

```
FROM python:3.6 
WORKDIR /APP

COPY . .
RUN python -m pip install -r requirements.txt  -i https://pypi.tuna.tsinghua.edu.cn/simple

CMD ["python","spider.py"]
```

It can be rewritten in the following format:

```
FROM python:3.6

WORKDIR /APP
COPY requirements.txt ./
RUN python -m pip install -r requirements.txt  -i https://pypi.tuna.tsinghua.edu.cn/simple
COPY spider.csv ./
COPY *.py ./
CMD ["python","spider.py"]
```

In this way, when you change the code in spider.py without adding new dependencies, you can reuse the cache of pip install.


## Finally

These are some of my insights when using Docker and docker-compose recently. I hope they can be helpful to everyone. This article will continue to be updated.

Ref：

- [You must understand these 17 Docker best practices!](https://shenxianpeng.github.io/2022/01/docker-best-practice/)

- [DOCKER BASIC TECHNOLOGY: LINUX NAMESPACE (UP)](https://coolshell.cn/articles/17010.html)

- [Use containers for development](https://docs.docker.com/language/golang/develop/)
