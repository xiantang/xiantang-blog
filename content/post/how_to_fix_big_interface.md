---
title: "Golang: 如何处理日渐膨胀的 interface"
date: 2022-02-13T20:23:51+08:00
author: "xiantang"
# lastmod: 
tags: []
categories: ["Golang"]
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

> The bigger the interface，the weaker the abstraction。[Go Proverbs](https://www.youtube.com/watch?v=PAAkCSZUG1c&t=317s)

TL;DR：如果你的 Golang interface 有太多函数导致你很难横向拓展，那就把它按照职责拆分成多个 interface，然后使用 embed **组合**起来。

倘若你有一些事件

## 遇到的问题

最近在重构一个管理配置的组件，我们会有一个接口并且有超过 5 个以上的 struct 实现这个接口，遇到了一些问题，就是**接口膨胀**的问题。当你最开始抽象出来一个 interface 的时候，它可能就只有 1 - 2 个函数，很漂亮，并且你的横向拓展的时候也非常的舒服。
但是很多时候现实的情况和你想象的不一样，因为每个实现可能也有自己想暴露出来的不同方法，这个时候你会把这些函数都暴露出来，每个实现为了满足接口都会去实现这个函数，这样就会导致接口膨胀。

## 举个例子

最开始我有一个接口叫做 `ConfigManager`，拥有两个函数一个是 `HandleResync`，一个是 `HandleWatch`。：

```Go
type ConfigManager interface {
 HandleResync()
 HandleWatch()
}
```

`HandleResync` 和 `HandleWatch` 都是对于 etcd 数据的拉取，拉取到数据之后，我们会将数据落盘，并且在内存里面也存储一份最新的副本。

同时这个接口是有两个实现类，一个是 `EtcdConfigManager`，一个是 `FileConfigManager`。这里名字比较随意，主要是要表达一个接口的多个实现。

```Go
type EtcdConfigManager struct {
 config *Config
}

type FileConfigManager struct {
 config *Config
}

```

但是应为业务不断增长，我们对于 `EtcdConfigManager` 需要多暴露出来两个接口用来做对内存中副本上报等行为。分别是 `GetConfig` 和 `SetConfig`。

但是对于 `FileConfigManager`，这个实现类其实是不需要暴露出内部的 config 的。

这个时候很多同学都会直接添加两个函数到 `ConfigManager` 接口，同时 `FileConfigManager` 会变成一个下边的样子：

```Go
type ConfigManager interface {
  HandleResync()
  HandleWatch()
  GetConfig() *Config
  SetConfig(*Config)
}

// impl for `ConfigManager`
type FileConfigManager struct {
   config *Config
}
...
func (f *FileConfigManager) GetConfig() *Config {
 // painc here
 panic("implement me")
}

func (f *FileConfigManager) SetConfig(c *Config) {
 // painc here
 panic("implement me")
}
```

虽然成功了解决了问题，但是会导致一些问题：

* 如果有一个新的配置需要管理，那么他将需要满足 4 个函数，来实现这个接口。
* 如果已经有了 10 个实现类实现了 `ConfigManager`，如果要添加一个新的函数到 `ConfigManager` 接口，那就需要这 10 个实现类都要更新，会有很多工作量。
* 对外部暴露太多内部的信息，如果涉及权限问题会导致资损等问题。

其实在公司的 codebase 里面已经出现了 10+ 个函数的 interface，横向拓展简直是一个噩梦。

## 我是如何解决的

因为受够了接口膨胀的问题，我可真算是绞尽脑汁，虽然 Golang 作者总是说要把接口控制小，但是其实并没告诉我们如何去防止接口膨胀。终于我在 Golang 的 io 包中找到了一个解决方案。

在 [io.go#83](https://github.com/golang/go/blob/master/src/io/io.go#L83) 到 [io.go#172](https://github.com/golang/go/blob/master/src/io/io.go#L172) 定义的接口中。

### 拆分接口

我们发现他按照职能拆分出了一堆只有 1 - 2 个函数小接口。
like：

```Go
type Reader interface {
 Read(p []byte) (n int, err error)
}
type Writer interface {
 Write(p []byte) (n int, err error)
}
type Closer interface {
 Close() error
}
type Seeker interface {
 Seek(offset int64, whence int) (int64, error)
}
```

### 拼接接口

采用增量拼接的方式将这些接口拼接起来：

```go
type Writer interface {
 Write(p []byte) (n int, err error)
}
type WriteSeeker interface {
 Writer
 Seeker
}
type ReadWriteSeeker interface {
 Reader
 Writer
 Seeker
}
```

### 转换接口

同时在传参的时候，只传递较小的接口，然后根据需要去转换到对应的大接口。


## 结论

* 接口小 effective golang 
ER 结尾

https://twitter.com/GIA917229015/status/1490336029844602880 

## 引用
* https://jishuin.proginn.com/p/763bfbd7078f
* (Using Interface Composition in Go As Guardrails)[https://rauljordan.com/2021/06/10/using-interface-composition-in-go-as-guardrails.html]