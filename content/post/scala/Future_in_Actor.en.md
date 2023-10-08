---
title: "How Actor Handles Blocking Messages"
date: 2020-01-15T17:51:36+08:00
tags: ["scala"]
categories: ["Chinese","scala","akka"]
draft: false
---

I noticed in the business code that a lot of 

`import scala.concurrent.ExecutionContext.Implicits.global`

is used as the thread pool for executing Future inside the Actor. I didn't think there was a problem before.
But after reading the akka source code, it seems a bit inappropriate.

Let's briefly talk about the architecture of Actor

When an Actor sends a message to another Actor, it sends this message to the recipient's mailbox

The mailbox is a class that implements Runnable, so it can be executed by a thread pool. So every time you send a message to an Actor
In fact, it is the recipient's Dispatcher that executes this message.

But the problem is if your application is IO intensive

Then whether you use the Actor's default defaultDispather or the Future's global implicit conversion method, it will be limited by the blocking tasks of the core threads of the thread pool, causing thread starvation

And because of the implementation of ForkJoinPool, it is a thread pool suitable for computation.

So here are two solutions

1. For IO-intensive tasks, you can use a custom thread pool to solve the problem

   But if there are a lot of sudden requests, it will still cause all the threads in the thread pool to be blocked and unable to respond to requests immediately.

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

2. Use `scala.concurrent.blocking for tasks with long blocking time, you can use this function to wrap your tasks `

```scala
Future {
  println("starting Future: " + n)
  blocking {
    Thread.sleep(3000)
  }
  println("ending Future: " + n)
}
```



When executing, ForkJoinPool will use the current thread as a thread in the expansion pool, that is, it exceeds the maximum number of threads, and then opens an additional thread for calculation.
It is the solution used by ForkJoinPool in the face of blocking situations.
The blocking function actually implements `ForkJoinPool.ManagedBlocker` and will allocate a thread to the Fork/Join Pool to perform blocking operations. Different from the traditional way of ForkJoinPool, it will not cause thread starvation.
