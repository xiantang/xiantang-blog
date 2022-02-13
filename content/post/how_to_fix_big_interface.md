---
title: "Golang: 如何处理日渐膨胀的 interface"
date: 2022-02-13T20:23:51+08:00
author: "xiantang"
# lastmod: 
tags: ["Golang","Refacotr"]
categories: ["Golang"]
images:
  - ./post/how_to_fix_big_interface.png
description:
draft: false
---


<!-- 
* 总是会先写一句话，同步背景和上下文
* 评论式写作引用一些大牛说的话
* 多一些有趣的跳转链接
* 在文章末尾推荐一些有趣的链接
* 先写提纲，再写内容 -->

> The bigger the interface，the weaker the abstraction。[Go Proverbs](https://www.youtube.com/watch?v=PAAkCSZUG1c&t=317s)

先说结论吧，如果你的 Golang interface 有太多函数导致你很难横向拓展，那就把它按照职责拆分成多个 interface，然后使用 embed **组合**起来。

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

同时在传参的时候，只传递较小的接口，然后根据需要去转换到其他接口。

```Golang
func WriteString(w Writer, s string) (n int, err error) {
 if sw, ok := w.(StringWriter); ok {
  return sw.WriteString(s)
 }
 return w.Write([]byte(s))
}
```

### 好处

这样好处是

* *尽量暴露少的信息给用户*：对于所有的实现类我们只需要实现必须实现的函数，不需要去满足上面接口的所有函数。
* *抽象能力更强*：因为你的接口只有 1 - 2 个函数所以横向拓展更加的简单，这也是为什么 io.Writer 接口能轻轻松松写出 20+ 个实现类的原因。

## 重构上面的代码

对于上面的代码，我们可以重构一下：

我们可以把拥有 4 个接口的 `ConfigManager` 重构成两个小接口，然后进行组合：

```golang
/*
type ConfigManager interface {
  HandleResync()
  HandleWatch()
  GetConfig() *Config
  SetConfig(*Config)
}
*/

type EventHandler interface {
   HandleResync()
   HandleWatch()
}

type DataHolder interface {
    GetConfig() *Config
    SetConfig(*Config)
}

type DataEventHandler struct {
     DataHolder
     EventHandler
}
```

这样 `FileConfigManager` 就可以只实现 `EventHandler` 接口了，减少了暴露的信息，并且可以不实现那些不想暴露的函数。

对于主逻辑其实也会比较简单：

```golang
func mainLoop(handler EventHandler) {
    // just example

    // resync
    handler.HandleResync()

    // watch
    handler.HandleWatch()

    // ...
    // report data
    if h,ok := handler.(DataEventHandler); ok {
     report(h.GetConfig())
    }
}

```

## 结论

总结一下，有下面几点我自己的最佳实践：

* 保证接口足够地小 1 - 2 个函数，这样就可以更加简单的去拓展接口，接口的名字可以使用单个单词，eg：`Reader`、`Writer`、`Closer`、`Seeker`。

* 使用接口组合的方式组合出大接口。

* 在主流程中使用接口转换的方式，将小接口转换成大接口。
* [Go：如何应对不断膨胀的接口](https://jishuin.proginn.com/p/763bfbd7078f)
* [Using Interface Composition in Go As Guardrails](https://rauljordan.com/2021/06/10/using-interface-composition-in-go-as-guardrails.html)
* [Go Interfaces with more than one method - Acceptable or unacceptable？](https://stackoverflow.com/questions/45395982/go-interfaces-with-more-than-one-method-acceptable-or-unacceptable)

## 推荐环节

最后最后和大家分享一些最近在看的好文，想过用周刊的方式发送但是因为看的比较零散，就放在每篇博文的最后，希望大家能够收获！

* [How to Write a Git Commit Message](https://cbea.ms/git-commit/) 推荐语：这个 git commit 提交消息的写法，对我这种每天只会写 fix xxxx issue 的人来说是很有用的。

* [Career Advice Nobody Gave Me：Never Ignore a Recruiter](https://index.medium.com/career-advice-nobody-gave-me-never-ignore-a-recruiter-4474eac9556) 程序员都不喜欢猎头，但是这篇文章告诉我们其实猎头是很重要的。

* [面对恐慌和无聊给程序员的一份自救指南](https://vikingz.me/save-yourself/) WFH 真的会让人徒增很多焦虑，这篇文章给了我一些灵感，之后可能会写一篇克服焦虑的文章。

* [《爱的沟通》](https://book.douban.com/subject/30248303/)教会了我如何去沟通，防止防御性倾听。
