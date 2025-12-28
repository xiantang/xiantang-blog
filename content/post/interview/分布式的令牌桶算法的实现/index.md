---
title: "分布式的令牌桶算法的实现"
date: 2020-04-09T01:37:56+08:00
lastmod: 2020-04-09T01:37:56+08:00
draft: false
tags: ["算法"]
categories: ["中文","算法"]
author: "xiantang"

---



## 什么是令牌桶算法?

令牌桶算法是一种限流算法，他与漏桶算法的实现是一种相反的实现。

漏桶算法是按照一定频率的速率进行漏水，然后对于我们的请求就可以想象成上边的水龙头。

![img](https://tva1.sinaimg.cn/large/00831rSTly1gdnjduhuivj30cb08b74u.jpg)

令牌桶算法则是定时的往桶中放入令牌，然后每次请求都会从令牌桶中获取一个令牌，如果桶中没有令牌，则拒绝请求或者阻塞直到令牌可以获得。

![img](https://tva1.sinaimg.cn/large/00831rSTly1gdnjhiarxgj30bp06pwek.jpg)

## 分布式的令牌桶算法

因为看到的令牌桶算法都是单机的，举个例子: RateLimiter 他就是一个线程级别的令牌桶算法。

因为需要实现一个分布式的令牌桶算法，所以我这边使用的是一个 Redis 作为令牌桶的容器。

然后我们来看看主要的令牌桶算法的思路:

其实他并没有创建一个线程不断的往令牌桶里边放数据，他采用的懒计算的方式进行处理，这样的好处是性能消耗比较小，可以避免一些无用的轮训操作。

其实我们可以吧令牌桶想象为一个对象:

```scala
case class RedisPermits(
                    name:String,
                    maxPermits: Long,
                    storePermits: Long,
                    intervalMillis: Long,
                    nextFreeTicketMillis: Long
                  ) {}
```

我来介绍一下这个令牌桶的成员变量:

Name: 表示这个令牌桶的名称，也就是存在redis中的key。

maxPermits: 表示令牌桶中令牌的数目。

storePermits: 表示令牌桶中当前令牌的数目。

intervalMillis: 每次放入令牌之间的间隔时间。根据请求的 QPS 求出。

nextFreeTicketMillis: 下一次能获取这些令牌的时间。



对于一个获取令牌的操作，我们可以判断为是否能够获取到令牌，也就是 nextFreeTicketMillis 是在当前时间之前还是之后。



### nextFreeTicketMillis 在当前时间之前

![image-20200409154830414](https://tva1.sinaimg.cn/large/00831rSTly1gdnkapnorij31fk0n045x.jpg)

通过图中的公式可以计算出当前存储的令牌数目。和你需要的令牌数目相互比较:

* 如果够用就减去需要使用的令牌数目，将 nextFreeTicketMillis 设置为 now。立马返回函数就行啦。
* 如果不够用就得到当前的令牌数目，将当前令牌数目设置为0，然后求出需要生成的数目，将 nextFreeTicketMillis 向后推，生成的时间。当前线程等待对应 nextFreeTicketMillis - now 的时间就能求出需要等待的时间。进行睡眠，睡眠结束就可以做相应的请求了。



### nextFreeTicketMillis 在当前时间之后

![image-20200409155633013](https://tva1.sinaimg.cn/large/00831rSTly1gdnkj2oezoj31ig0dk79x.jpg)

nextFreeTicketMillis 因为在当前时间之后所以当前令牌桶肯定是没有数据的，所以我们需要将睡眠的时间往后拖就好了，就是 nextFreeTicketMillis =+ intervalMillis*need 然后当前线程睡眠 nextFreeTicketMillis - now 的时间就行啦。



## 优点

令牌桶算法可以采用将 maxPermits 也就是最大令牌数量设置为 1 方式，将请求打均匀，非常适合需要匀速调用的场景。

并且使用本实现可以将请求阻塞起来，保证请求能够都打到，其实也是一个削峰的作用。
