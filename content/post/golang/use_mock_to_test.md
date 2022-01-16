---
title: "使用 Mock 和 Interface 进行 Golang 单测"
date: 2022-01-07T01:37:56+08:00
lastmod: 2022-01-07T01:37:56+08:00
draft: false
tags: ["Golang"]
categories: ["Golang"]
author: "xiantang"
images:
   - ./post/golang/cover.png
description: "golang单元测试最佳实践 Go 语言 自动化 测试 golang 单元测试 数据库 golang 单元测试 mock golang 单元测试规范"

---

<!-- * 总是会先写一句话，同步背景和上下文
* 评论式[[写作]]引用一些大牛说的话
* 多一些有趣的跳转链接
* 先写提纲，再写内容 -->

<!-- ## 一句话引出文章 -->

> 在工作中我经常会发现很多工程师的 `Golang` 单测是写的有问题的，只是单纯的调用代码做输出，并且会包含各种 `IO` 操作，导致单测无法到处运行。

## 使用 Mock 和 Interface 进行 Golang 单测

本文将介绍 `Golang` 中如何正确的做单测。

### 什么是单元测试？单元测试的特点

单元测试是质量保证十分重要的一环，好的单元测试不仅能及时地发现问题，更能够方便地调试，提高生产效率，所以很多人认为写单元测试是需要额外的时间，会降低生产效率，是对单元测试最大的偏见和误解。

单测会将对应测试的模块隔离出来进行测试，所以我们要尽可能把所有相关的外部依赖都移除，只对相关的模块进行单测。

所以大家看到的在业务代码仓库中的一些在 `client` 模块中调用 `HTTP` 的单测其实是不规范的，因为 `HTTP` 是外部依赖，你的目标服务器如果有故障，那么你的单测就会失败。

```go
func Test_xxx(t *testing.T) {
 DemoClient := &demo.DemoClient{url: "http://localhost:8080"}
 DemoClient.Init()
 resp := DemoCliten.DoHTTPReq()
 fmt.Println(resp)
}
```

上面这个例子中 `DemoClient` 在做 `DoHTTPReq` 方法的时候，会调用 `http.Get` 方法，这个方法是中包含了外部依赖也就是说他会去请求本地的服务器，如果有一个新的同事刚拿到你的代码，并且本地是没有这个服务器的话，那么你的单测就会失败。

并且上面这个例子中，对于 `DoHTTPReq` 这个函数只是简单的做了一个输出，没有对返回值做任何检查，如果内部逻辑修改并且返回值修改了，虽然你的测试还是能够 `pass` 但是其实你的单测是不起作用的。

从上面的例子中我们可以总结出两个单测特点:

* 没有外部依赖，尽量无副作用，能够到处运行
* 对输出进行检查

此外我还想提及的一点就是对于单测的编写难度其实是有排序的：

UI > Service > Utils

所以对于单测的编写，我们会优先考虑对 `Utils` 的单测, 因为 `Utils` 不会有太多的依赖。其次是对于 `Service` 的单测，因为 `Service` 的单测主要是对上游服务和数据库的依赖，只需要分离出依赖就可以进行逻辑的测试。

那该如何分离出依赖呢？我们走到下一节，我们将会介绍如何分离出依赖。

### 什么是 Mock？

对于 `IO` 的依赖，我们可以使用 `Mock` 来模拟数据，这样我们就可以不用担心数据源不稳定的问题了。

那么什么是 `Mock` 呢？我们又该如何 `Mock` 呢？ 可以想想一个场景，就是你和你的同事正在进行合作的项目开发，你这边的进展比较快，已经快完成你的开发了，但是你的同事进展稍慢，并且你还依赖他的服务。你要怎么不 `block` 你的进展继续开发呢？

这里就可以使用到 `Mock` 了，就是你可以和你的同事先制定好需要交互的数据格式，在你的测试代码中，你可以编写一个可以产生对应数据格式的客户端，并且这些数据都是虚假的，然后你就可以继续编写你的代码，等到你的同事完成了他那部分的代码，你就只需要将 `Mock Clients`替换为真实的 `Clients` 就可以了。这就是 `Mock` 的作用。

同样的，我们也可以使用 `Mock` 来对需要测试模块所依赖的数据进行模拟。下面就是一个例子：

```go
package myapp_test
// TestYoClient provides mockable implementation of yo.Client.
type TestYoClient struct {
    SendFunc func(string) error
}
func (c *TestYoClient) Send(recipient string) error {
    return c.SendFunc(recipient)
}
func TestMyApplication_SendYo(t *testing.T) {
    c := &TestYoClient{}
    a := &MyApplication{YoClient: c}
    // Mock our send function to capture the argument.
    var recipient string
    c.SendFunc = func(s string) error {
        recipient = s
        return nil
    }
    // Send the yo and verify the recipient.
    err := a.Yo("susy")
    ok(t, err)
    equals(t, "susy", recipient)
}
```

我们会有一个 `MyApplication` 同时他又依赖了一个发送上报的 `YoClient`。上面的代码中我们会将依赖的 `YoClient` 替换为 `TestYoClient`，这样代码在调用 `MyApplication.Yo` 时，其实执行的是 `TestYoClient.Send`，这样我们就可以自定义外部依赖的输入和输出了。

同样可以发现一个很有趣的地方，就是我们将 `TestYoClient` 的 `SendFunc` 替换为 `func(string) error`，这样我们就可以更加灵活的控制输入和输出了。对于不同的测试，我们只需要更改 `SendFunc` 的值就可以了。这样每个测试我们都可以随意的控制输入和输出。

此时你会发现另外一个问题，就是如果想要将 `TestYoClient` 成功注入到 `MyApplication` 中，对应的成员变量就需要是 `TestYoClient` 这个具体类型或者是满足 `Send()` 方法的接口类型。但是如果我们使用具体类型的话，井没办法做到真实的 `Client` 与 `Mock Client` 的替换了。

所以我们可以使用接口类型来替换。

### 什么是 Interface？

在 `Golang` 中接口可能和你接触的其他语言的接口不同，在 `Golang` 中接口是一个函数的集合。并且 `Golang` 的接口是隐式的，不需要显式的定义。

我个人也非常同意这种设计，因为经过多次的实践，我发现事先定义好的抽象往往都是无法很准确的描述具体实现的行为的。所以需要事后做抽象, 与其写类型来满足 `interface`，不如写接口来满足使用要求。

> Always *abstract* things when you actually need them, never when you just foresee that you need them.

我个人的推荐是对于几个相似的流程，我们可以先通过写几个结构体来组织代码，然后发现这些结构体有相似的行为之后，就可以抽象出一个接口来描述这些行为，这样才是最准确的。

同时对于 `Golang` 中的接口所包含的方法数目也需要加以限制，不能太多，1-3 个方法就可以了。其中的原因是这样的，如果你的接口中包含太多方法，你新增一个实现类型的代码就会很麻烦，而且这样的代码也不好维护。同样如果你的接口有很多种实现，并且方法有很多，那么你再多添加一个函数加入接口也会很困难，你需要在每个结构体中都实现这些方法。

回到主题，对于 `YoClient` 来说，最初如果我们不是采用 `TDD` 的方式，那么 `MyApplication` 的所依赖的一定是一个正式的具体类型，此时我们可以在测试代码中写一个 `TestYoClient` 类型的实例，提取出共有的函数抽出接口，然后再去将 `MyApplication` 中的 `YoClient` 替换为接口类型。

这样就可以达成我们的目的了。

```go
package myapp
type MyApplication struct {
    YoClient interface {
        Send(string) error
    }
}
func (a *MyApplication) Yo(recipient string) error {
    return a.YoClient.Send(recipient)
}
```

### 其他的一些例子

此外我还提供了一个例子供参考，主要是从正式生产的代码中找到的，屏蔽了敏感信息的例子。

这个例子是对 `etcd` 这个外部依赖的 `mock`。

```golang
type ETCD interface {
 GetWithTimeout(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error)
 Watch(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan
}

type MockEtcdClient struct {
 GetWithTimeoutFunc func(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error)
 WatchFunc          func(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan
}

func (m MockEtcdClient) GetWithTimeout(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error) {
 return m.GetWithTimeoutFunc(key, opts...)
}

func (m MockEtcdClient) Watch(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan {
 return m.WatchFunc(ctx, key, opts...)
}

```

一个单测的例子:

```go
func Test_saveTestConf(t *testing.T) {
 etcd := store.MockEtcdClient{
  GetWithTimeoutFunc: func(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error) {
   return &clientv3.GetResponse{
    Kvs: []*mvccpb.KeyValue{
     {
      Key:   []byte("/xxxx/xxx/config"),
      Value: []byte("{\"xxx\":\"xxx\"}"),
     },
    },
   }, nil
  },
  WatchFunc: func(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan {
   return nil
  },
 }

 configKey, err := saveTestConf(etcd ,"xxxx", "/xxxx/xxx/config")
 if err != nil {
  t.Error(err)
 }
 assert.Equal(t, "/xxxx/xxx/config", configKey)
}


```

### other tips

关于测试我这边还有一些你可能不知道的小技巧

#### golang 的 interal 与 external 测试

对于一个包的导出方法以及变量你可以在同一个包下建立 `test` 文件来测试，只需要将包名后缀改为 `_test` 即可。这样就可以做到 `black box testing`。好处是你可以以调用者的视角来描述你的测试，而不是以内部的视角来写你的测试。 也可以作为一个示例给使用者看一下如何使用。

```go
// in example.go
package example

var start int

func Add(n int) int {
  start += n
  return start
}

// in example_test.go
package example_test

import (
 "testing"

 . "bitbucket.org/splice/blog/example"
)

func TestAdd(t *testing.T) {
  got := Add(1)
  if got != 1 {
    t.Errorf("got %d, want 1", got)
  }
}
```

另外你也可以对未导出的方法和变量进行测试，可以创建一个尾缀为 `_internal_test` 的文件来标识你是想要测试未导出的方法和变量的。

## 总结

* `Golang` 单测的特点：
  * 没有外部依赖，尽量无副作用，能够到处运行
  * 需要对输出进行检查
  * 可以作为一个示例给使用者看一下如何使用

* `Golang` 可以使用接口来替换依赖

### 有趣的链接推荐

最后最后和大家分享一下参考的链接，以及一些最近在看的好文,因为看的比较零散，一并写给大家，希望大家能够收获。

* [如何 mock file system](https://talks.golang.org/2012/10things.slide#8)
* [mock struct 要如何写](https://medium.com/@benbjohnson/structuring-tests-in-go-46ddee7a25c) 通过函数变量来实现复用真的很方便
* [不为人知的测试技巧](https://splice.com/blog/lesser-known-features-go-test/)
* [如何不努力也能财富自由](https://geekplux.com/newsletters/2) 赚钱永远是主题
* [gopher-reading-list](https://github.com/enocom/gopher-reading-list) 一路遍历下来收获很大的
* [What “accept interfaces, return structs” means in Go](https://medium.com/@cep21/what-accept-interfaces-return-structs-means-in-go-2fe879e25ee8)总是在你实际需要的时候[抽象]东西，而不是在你只是预见你需要它们的时候。
* [天涯讨论房价神贴](https://github.com/xiantang/kkndme_tianya)
