---
title: "Analysis of Akka Source Code"
date: 2020-01-15T17:26:53+08:00
tags: ["scala"]
categories: ["Chinese","scala","akka"]
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

## Logic of subscribe

Synchronously add subscriber and to into subscriptions. The diff should be compared with the previous one to ensure that it will not be sent repeatedly?

```scala
def subscribe(subscriber: Subscriber, to: Classifier): Boolean = subscriptions.synchronized {
  val diff = subscriptions.addValue(to, subscriber)
  addToCache(diff)
  diff.nonEmpty
}
```

![image-20200109114040999](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi6sifoj312k06878y.jpg)

![image-20200109131215939](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi7d0o9j30t40f2tho.jpg)

There is an important method in addValue, which is to find the corresponding class from `subkeys`, that is, subscribe.

You can imagine `subkeys` as a node in a multi-branch tree, where the key of the node is the type of subscription source, and the value is the corresponding subscriber Actor.

Then this node also has its own `subkeys`. The keys of these subkeys are subclasses of the upper type, and the subscribers are extensions of the upper subscribers.

![image-20200109140449787](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi7rh9jj30ss0g0wit.jpg)

For duplicate subscriptions, it will deduplicate once, similar to arc diff.

For ` system.eventStream.subscribe(jazzListener, classOf[Jazz])`

![image-20200109120145086](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi88df2j311m05gadr.jpg)

It will generate a diff like this and add it to the cache.

The data structure of the cache is a `private var cache = Map.empty[Classifier, Set[Subscriber]]` Map, which are the subscription source and the subscriber respectively.

For `system.eventStream.subscribe(musicListener, classOf[AllKindsOfMusic]) ` 

![image-20200109120406852](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi8ptj5j31j804kjuu.jpg)

## Logic of publish

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

The logic of publish is relatively simple. First, it will find the corresponding className from the event.

Then it goes through the cache logic. If it does not exist in the cache, it will update the corresponding key to the subkeys multi-branch tree, find the corresponding subscriber, and update it to the cache.

Finally, it traverses recv and calls the publish function.

```scala
  protected def publish(event: Any, subscriber: ActorRef) = {
    if (sys == null && subscriber.isTerminated) unsubscribe(subscriber)
    else subscriber ! event
  }
```

# Actor Initialization

```scala
val pinger = system.actorOf(Props[Pinger], "pinger")
val ponger = system.actorOf(Props(classOf[Ponger], pinger), "ponger")
```

It will call the actorOf method in ActorSystem

```scala
def actorOf(props: Props): ActorRef =
if (guardianProps.isEmpty) guardian.underlying.attachChild(props, systemService = false)
else
throw new UnsupportedOperationException(
  "cannot create top-level actor from the outside on ActorSystem with custom user guardian")
```

It will create a new Child Actor under the guard Actor

It will call the following makeChild method:

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



## Implementation of Tell

```scala
final def sendMessage(message: Any, sender: ActorRef): Unit =
  sendMessage(Envelope(message, sender, system))
```

Wrap the message as an envelope and call the sendMessage method of Cell

This is because Cell has implemented

![image-20200109195143660](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxdi95pdbj31kc09utcl.jpg)

Dispatch Trait

In fact, it is the sendMessage method in the Dispatch trait that is executed

```scala
def sendMessage(msg: Envelope): Unit =
    try {
      val msgToDispatch =
        if (system.settings.SerializeAllMessages) serializeAndDeserialize(msg)
        else msg

      dispatcher.dispatch(this, msgToDispatch)
    } catch handleException
```

But I still have a question, is the dispatcher my own defined dispatcher?

Then call the dispatch function of the dispatcher corresponding to this Actor

```scala
protected[akka] def dispatch(receiver: ActorCell, invocation: Envelope): Unit = {
    val mbox = receiver.mailbox
    mbox.enqueue(receiver.self, invocation)
    registerForExecution(mbox, true, false)
  }
```

Throw the envelope into the mailbox of the corresponding receiver, and then pass the mbox as a parameter into registerForExecution to register in the thread pool.

And this thread pool is the thread pool I preset, and the dispatcher is just a wrapper for this thread pool.

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

Use the internal thread pool to execute this MailBox object

Since MailBox can be executed, it must have implemented the Runnable method. Let's take a look at its implementation:

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

Let's mainly look at the implementation of the processMailbox method

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



Very simple implementation, using tail recursion,

1. First calculate left, which is the throughput of the dispatcher
2. Then dequeue an element from the queue
3. Call the invoke method of the actor
4. Continue to call down until left < 1 or

There are two key parameters,

Throughput is the number of messages consumed by a single execution of `executorService.execute(mbox)`. Messages exceeding this number will be handed over to the next execution of this mbox.

`deadlineNs` is the deadline for sending throughput messages, ensuring that the throughput messages are completed within the deadline.

The invoke method of calling the actor will call the receiveMessage method of ActorCell below

`actor.aroundReceive(behaviorStack.head, msg)`

Get the Receive partial function at the top of the stack and call aroundReceive to perform operations

```scala
protected[akka] def aroundReceive(receive: Actor.Receive, msg: Any): Unit = {
  // optimization: avoid allocation of lambda
  if (receive.applyOrElse(msg, Actor.notHandledFun).asInstanceOf[AnyRef] eq Actor.NotHandled) {
    unhandled(msg)
  }
}
```

If `receive` does not match the corresponding message, the partial function's `applyOrElse` is used to capture the remaining value domain, and it is determined whether the return value is equal to `NotHandled`.

```scala
def unhandled(message: Any): Unit = {
  message match {
    case Terminated(dead) => throw DeathPactException(dead)
    case _                => context.system.eventStream.publish(UnhandledMessage(message, sender(), self))
  }
}
```

A pattern match is made on the message, and if it is an unhandled message, it is sent out as a subscription.

Here we can use a subscriber `system.eventStream.subscribe(listener, classOf[UnhandledMessage])` to subscribe to these messages for log output.
