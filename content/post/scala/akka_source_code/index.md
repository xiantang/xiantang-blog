---
title: "Akka 源码解析"
date: 2020-01-15T17:26:53+08:00
tags: ["scala"]
categories: ["中文","scala","akka"]
draft: false
---



```scala
object Main1 extends App {
  val system = ActorSystem("HelloSystem")
  val jazzListener = system.actorOf(Props[Listener])
  val musicListener = system.actorOf(Props[Listener])
  system.eventStream.subscribe(jazzListener, classOf[Jazz]) // jazzListener 订阅 Jazz 事件
  system.eventStream.subscribe(musicListener, classOf[AllKindsOfMusic]) // musicListener 订阅 AllKindsOfMusic 以及它的子类 事件

  // 只有 musicListener 接收到这个事件
  system.eventStream.publish(Electronic("Parov Stelar"))

  // jazzListener 和 musicListener 都会收到这个事件
  system.eventStream.publish(Jazz("Sonny Rollins"))
}

```

## subscribe 逻辑

同步地将 subcriber 和 to 加入到 subscriptions 中，diff 应该是和之前的一次比较保证不会重复发送？

```scala
def subscribe(subscriber: Subscriber, to: Classifier): Boolean = subscriptions.synchronized {
  val diff = subscriptions.addValue(to, subscriber)
  addToCache(diff)
  diff.nonEmpty
}
```

![image-20200109114040999](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi6sifoj312k06878y.jpg)

![image-20200109131215939](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi7d0o9j30t40f2tho.jpg)

addValue 中有个比较重要的方法，就是从 `subkeys` 也就是 subscribe 中到找对应的类。

可以将 `subkeys` 想象为一个多叉树中的一个节点，节点的 key 为订阅源类型，value 为所对应的订阅者 Actor

然后这个节点也有自己的 `subkeys` 这些 subkeys 为的 key 为上层类型的子类，同时订阅者是与是上层订阅者的拓展

![image-20200109140449787](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi7rh9jj30ss0g0wit.jpg)

对于重复的订阅，他会做一次去重，类似于 arc diff

对于 ` system.eventStream.subscribe(jazzListener, classOf[Jazz])`

![image-20200109120145086](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi88df2j311m05gadr.jpg)

会产生一个这样的 diff 然后加入到 cache 中

cache 的数据结构是一个 `private var cache = Map.empty[Classifier, Set[Subscriber]]` Map 分别是订阅源和订阅者

对于 `system.eventStream.subscribe(musicListener, classOf[AllKindsOfMusic]) ` 

![image-20200109120406852](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi8ptj5j31j804kjuu.jpg)

## publish 逻辑

```scala
def publish(event: Event): Unit = {
    val c = classify(event)
    val recv =
      if (cache contains c) cache(c) // c will never be removed from cache
      else
        subscriptions.synchronized {
          if (cache contains c) cache(c)
          else {
            addToCache(subscriptions.addKey(c))
            cache(c)
          }
        }
    recv.foreach(publish(event, _))
  }
```

publish 逻辑较为简单，首先会从 event 中找出对应 className 

然后走缓存逻辑，如果不在缓存中存在，就将对应的 key 更新到 subkeys 多叉树中，找到对应的订阅者，并且更新到 cache 中。 

最后遍历 recv 调用 publish 函数。

```scala
  protected def publish(event: Any, subscriber: ActorRef) = {
    if (sys == null && subscriber.isTerminated) unsubscribe(subscriber)
    else subscriber ! event
  }
```

# Actor 初始化

```scala
val pinger = system.actorOf(Props[Pinger], "pinger")
val ponger = system.actorOf(Props(classOf[Ponger], pinger), "ponger")
```

会调用 ActorSystem 中的 actorOf 方法

```scala
def actorOf(props: Props): ActorRef =
if (guardianProps.isEmpty) guardian.underlying.attachChild(props, systemService = false)
else
throw new UnsupportedOperationException(
  "cannot create top-level actor from the outside on ActorSystem with custom user guardian")
```

会从守卫 Actor 下面创建一个新的 Child Actor

会调用下边的 makeChild 方法：

Children.scala

```scala
val actor =
        try {
          val childPath = new ChildActorPath(cell.self.path, name, ActorCell.newUid())
          cell.provider.actorOf(
            cell.systemImpl,
            props,
            cell.self,
            childPath,
            systemService = systemService,
            deploy = None,
            lookupDeploy = true,
            async = async)
        } 

initChild(actor)
actor.start() // 绑定 actor 到 dispatcher 
actor  // 返回 actor ref
```



## Tell 实现

```scala
final def sendMessage(message: Any, sender: ActorRef): Unit =
  sendMessage(Envelope(message, sender, system))
```

将 message 包装为信封，调用 Cell 的 sendMessage 方法

是因为 Cell 实现了

![image-20200109195143660](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi95pdbj31kc09utcl.jpg)

Dispatch 特质

其实是执行的 Dispatch 特质中的 sendMessage 方法

```scala
def sendMessage(msg: Envelope): Unit =
    try {
      val msgToDispatch =
        if (system.settings.SerializeAllMessages) serializeAndDeserialize(msg)
        else msg

      dispatcher.dispatch(this, msgToDispatch)
    } catch handleException
```

但是我仍然有个问题，dispatcher 是我自己规定的 dispather？

再调用这个 Actor 所对应的 dispatcher 的 dispatch 函数

```scala
protected[akka] def dispatch(receiver: ActorCell, invocation: Envelope): Unit = {
    val mbox = receiver.mailbox
    mbox.enqueue(receiver.self, invocation)
    registerForExecution(mbox, true, false)
  }
```

将信封丢入对应接收者的 mailbox 中，然后将 mbox 作为参数传入 registerForExecution 注册到线程池中。

而这个线程池就是我预设的线程池，dispacher 只是对这个线程池做一层封装。

```scala
protected[akka] override def registerForExecution(
      mbox: Mailbox,
      hasMessageHint: Boolean,
      hasSystemMessageHint: Boolean): Boolean = {
    if (mbox.canBeScheduledForExecution(hasMessageHint, hasSystemMessageHint)) { //This needs to be here to ensure thread safety and no races
      if (mbox.setAsScheduled()) {
        try {
          //!!!!
          executorService.execute(mbox)
          true
        } catch {
       		...
        }
      } else false
    } else false
  }
```

使用内部的线程池来执行这个 MailBox 对象

既然 MailBox 可以被执行它一定实现了 Runnable 方法来看看他的实现：

```scala 
override final def run(): Unit = {
    try {
      if (!isClosed) { //Volatile read, needed here
        processAllSystemMessages() //First, deal with any system messages
        processMailbox() //Then deal with messages
      }
    } finally {
      setAsIdle() //Volatile write, needed here
      dispatcher.registerForExecution(this, false, false)
    }
  }
```

来主要看一下 processMailbox 方法的实现吧

```scala
@tailrec private final def processMailbox(
      left: Int = java.lang.Math.max(dispatcher.throughput, 1),
      deadlineNs: Long =
        if (dispatcher.isThroughputDeadlineTimeDefined)
          System.nanoTime + dispatcher.throughputDeadlineTime.toNanos
        else 0L): Unit =
    if (shouldProcessMessage) {
      val next = dequeue()
      if (next ne null) {
        if (Mailbox.debug) println(actor.self + " processing message " + next)
        actor.invoke(next)
        if (Thread.interrupted())
          throw new InterruptedException("Interrupted while processing actor messages")
        processAllSystemMessages()
        if ((left > 1) && (!dispatcher.isThroughputDeadlineTimeDefined || (System.nanoTime - deadlineNs) < 0))
          processMailbox(left - 1, deadlineNs)
      }
    }
```



很简单的实现，使用了尾递归的方式，

1. 首先计算出 left 也就是分发器的吞吐量
2. 然后从队列里面出队一个元素
3. 调用 actor 的 invoke 方法
4. 继续向下调用直到 left < 1 或者

有两个关键的参数，

throughput 也就是单次执行 `executorService.execute(mbox)` 所消费消息的数量。超出这个数量的消息将会交给下次执行这个 mbox 的时候执行。

`deadlineNs` 发送 throughput 数量消息的截止时间，保证 throughput 的消息要在截止时间内完成。

调用 actor 的 invoke 方法下面会调用 ActorCell 的 receiveMessage 方法

`actor.aroundReceive(behaviorStack.head, msg)`

获得栈顶的 Receive 偏函数，调用 aroundReceive 来执行操作

```scala
protected[akka] def aroundReceive(receive: Actor.Receive, msg: Any): Unit = {
  // optimization: avoid allocation of lambda
  if (receive.applyOrElse(msg, Actor.notHandledFun).asInstanceOf[AnyRef] eq Actor.NotHandled) {
    unhandled(msg)
  }
}
```

如果 receive 没有 match 对应的 message，使用了偏函数的 applyOrElse 捕获剩下的值域，判断返回值是否和 NotHandled 相等。

```scala
def unhandled(message: Any): Unit = {
  message match {
    case Terminated(dead) => throw DeathPactException(dead)
    case _                => context.system.eventStream.publish(UnhandledMessage(message, sender(), self))
  }
}
```

对 message 做一次模式匹配，如果是没有 handle 的 message 就将它作为订阅发出。

这里我们可以使用一个订阅者 `system.eventStream.subscribe(listener, classOf[UnhandledMessage]) ` 来订阅这些消息，进行日志输出。