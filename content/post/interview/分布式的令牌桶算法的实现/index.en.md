---
title: "Implementation of Distributed Token Bucket Algorithm"
date: 2020-04-09T01:37:56+08:00
lastmod: 2020-04-09T01:37:56+08:00
draft: false
tags: ["algorithm"]
categories: ["English","algorithm"]
author: "xiantang"

---

## What is the Token Bucket Algorithm?

The token bucket algorithm is a rate limiting algorithm, which is the opposite implementation of the leaky bucket algorithm.

The leaky bucket algorithm leaks at a certain frequency rate, and our requests can be imagined as the faucet above.

![img](https://tva1.sinaimg.cn/large/00831rSTly1gdnjduhuivj30cb08b74u.jpg)

The token bucket algorithm, on the other hand, periodically puts tokens into the bucket, and each request will get a token from the token bucket. If there are no tokens in the bucket, the request is rejected or blocked until a token can be obtained.

![img](https://tva1.sinaimg.cn/large/00831rSTly1gdnjhiarxgj30bp06pwek.jpg)

## Distributed Token Bucket Algorithm

Because all the token bucket algorithms I've seen are single-machine, for example: RateLimiter is a thread-level token bucket algorithm.

Because I need to implement a distributed token bucket algorithm, I use Redis as the container for the token bucket.

Let's look at the main idea of the token bucket algorithm:

In fact, it does not create a thread to continuously put data into the token bucket, but uses a lazy calculation method to handle it. This has the advantage of low performance consumption and can avoid some useless polling operations.

We can imagine the token bucket as an object:

```scala
case class RedisPermits(
                    name:String,
                    maxPermits: Long,
                    storePermits: Long,
                    intervalMillis: Long,
                    nextFreeTicketMillis: Long
                  ) {}
```

Let me introduce the member variables of this token bucket:

Name: Represents the name of this token bucket, which is the key in redis.

maxPermits: Represents the number of tokens in the token bucket.

storePermits: Represents the current number of tokens in the token bucket.

intervalMillis: The interval time between each token insertion. Calculated based on the request's QPS.

nextFreeTicketMillis: The next time these tokens can be obtained.

For a token acquisition operation, we can judge whether we can get the token, that is, whether the nextFreeTicketMillis is before or after the current time.

### nextFreeTicketMillis is before the current time

![image-20200409154830414](https://tva1.sinaimg.cn/large/00831rSTly1gdnkapnorij31fk0n045x.jpg)

The current number of tokens stored can be calculated through the formula in the picture. Compare it with the number of tokens you need:

* If it is enough, subtract the number of tokens needed, set nextFreeTicketMillis to now, and return the function immediately.
* If it is not enough, get the current number of tokens, set the current number of tokens to 0, then find out the number needed, push nextFreeTicketMillis back, generate the time. The current thread waits for the corresponding nextFreeTicketMillis - now time to find out the waiting time. Go to sleep, and you can make the corresponding request after waking up.



### nextFreeTicketMillis is after the current time

![image-20200409155633013](https://tva1.sinaimg.cn/large/00831rSTly1gdnkj2oezoj31ig0dk79x.jpg)

Since nextFreeTicketMillis is after the current time, the current token bucket must be empty, so we need to drag the sleep time back, that is, nextFreeTicketMillis =+ intervalMillis*need, and then the current thread sleeps for nextFreeTicketMillis - now time.



## Advantages

The token bucket algorithm can use the method of setting maxPermits, that is, the maximum token quantity, to 1, to evenly distribute the requests, which is very suitable for scenarios that need to be called at a uniform speed.

And using this implementation can block the requests, ensuring that all requests can be hit, which is actually a peak shaving function.
