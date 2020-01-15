每个流程都是实现于 EventHandler

Called when a publisher has published an event to the RingBuffer

```scala
public interface EventHandler<T>
{
    /**
     * Called when a publisher has published an event to the {@link RingBuffer}
     *
     * @param event      published to the {@link RingBuffer}
     * @param sequence   of the event being processed
     * @param endOfBatch flag to indicate if this is the last event in a batch from the {@link RingBuffer}
     * @throws Exception if the EventHandler would like the exception handled further up the chain.
     */
    void onEvent(T event, long sequence, boolean endOfBatch) throws Exception;
}
```



MessageExpiresHandler` 

获取对应的 Message 的过期时间，判断是否过期

`expires > 0 && created + expires < System.currentTimeMillis()`





MessageStatusCheckHandler

```scala
if (!event.getSkipped) {
      RedisClients.withClient { redis ⇒
        val message = event.getMessage
        val skipped = redis.exists(Names.messageStatusKey(message))
        if (skipped) {
          logger.info(s"Message already sent. skip it ${Formatter.format(event)}")
        }
        event.setSkipped(skipped)
      }
    }
```

判断消息是否发送



MessageDispatchHandler

根据 消息的

```scala
val channels = channelMappings(event.getMessage.getClass.getName).filter(_.circuitBreaker.checkState())
val _channels = filter.fold(channels) { f ⇒ channels.filter(wrapper ⇒ f(wrapper)) }
val channelWrapper = if (_channels.lengthCompare(1) > 0) {
  _channels.minBy(_.index)
} else {
  _channels.head
}
channelWrapper.hit.incrementAndGet()
channelWrapper
```

