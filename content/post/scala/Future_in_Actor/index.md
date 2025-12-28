---
title: "Actor 如何处理阻塞消息"
date: 2020-01-15T17:51:36+08:00
tags: ["scala"]
categories: ["中文","scala","akka"]
draft: false
---

观察了一下业务的代码中发现在 Actor 中采用了很多 

`import scala.concurrent.ExecutionContext.Implicits.global`

来作为 Actor 内部的执行 Future 的线程池，之前觉得好像也没啥问题。
但是在看完 akka 源码后发现好像有些不妥。

简单的讲一下 Actor 的架构吧

当一个Actor 向另外一个 Actor 中发送信息会将这条信息发送到接受的Actor的 mailbox 中

mailbox 是一个实现 Runnable 的类，所以可以用线程池执行，所以每当你向一个Actor 发送一条消息的时候
其实是用 接受者的 Dispatcher 来执行这条消息的。

但是问题是如果你的应用是 IO 密集型的应用

那么无论你使用 Actor 的默认的 defaultDispather 或者 Future 的global 隐式转换方式，都会因为线程池的核心线程被阻塞任务限制，导致线程饥饿

并且因为ForkJoinPool 的实现，是一个适合计算的线程池。

所以这里给出两个方案

1. 对于 IO 密集型的任务可以采用自定义线程池的方式进行解决

   但是如果突发的请求很多，仍然会导致线程池中线程都在阻塞，无法立马响应请求的情况。

```scala
implicit val blockingDispatcher: MessageDispatcher = context.system.dispatchers.lookup("blocking-io-dispatcher")

blocking-io-dispatcher {
  type = Dispatcher
  executor = "thread-pool-executor"
  thread-pool-executor {
   fixed-pool-size = 32
  }
  throughput = 1
}
```

2. 使用 `scala.concurrent.blocking对于阻塞时间较长的任务，可以使用这个函数来包裹你的任务 `

```scala
Future {
  println("starting Future: " + n)
  blocking {
    Thread.sleep(3000)
  }
  println("ending Future: " + n)
}
```



在执行的时候会在 ForkJoinPool 会使用当前的线程作为拓展池中的线程，也就是超出最大线程数，再额外开出一个线程进行计算。
是 ForkJoinPool 在面对阻塞的情况下使用的方案。
blocking 函数其实在实现了 `ForkJoinPool.ManagedBlocker`  会给分配 Fork/Join Pool 给一个线程，执行阻塞的操作。与 ForkJoinPool 的传统方式不同，所以不会产生线程饥饿的现象。