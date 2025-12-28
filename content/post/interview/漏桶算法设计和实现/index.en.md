---
title: "Design and Implementation of the Leaky Bucket Algorithm"
date: 2020-04-05T01:37:56+08:00
lastmod: 2020-04-05T01:37:56+08:00
draft: false
tags: ["algorithm"]
categories: ["Chinese","algorithm"]
author: "xiantang"
---

## What is the Leaky Bucket Algorithm?

As the name suggests, the Leaky Bucket algorithm uses a leaky bucket to limit traffic.

Because there is a hole at the bottom of the bucket, it will leak water at regular intervals, and we can imagine the traffic as water falling into the bucket from above.

This leads to two situations. If the speed at which traffic is injected into the bucket is slower than the speed at which the bucket leaks, the bucket will be in an empty state, that is, it is not overloaded.

The second situation is that if the speed of traffic injection into the bucket is faster than the bucket, then the bucket will gradually exceed its maximum capacity. For the overflow traffic, the bucket will reject it to prevent further traffic from entering.

![image-20200405231856133](https://tva1.sinaimg.cn/large/00831rSTly1gdjauntjbcj30sy0j840y.jpg)

## Implementation in Java

```java
package info.xiantang.limiter;

class FunnelRateLimiter {

    // 容量
    private final int capacity;
    // 每毫秒漏水的速度
    private final double leakingRate;
    // 漏斗没有被占满的体积
    private int emptyCapacity;
    // 上次漏水的时间
    private long lastLeakingTime = System.currentTimeMillis();


    FunnelRateLimiter(int capacity, double leakingRate) {
        this.capacity = capacity;
        this.leakingRate = leakingRate;
        // 初始化为一个空的漏斗
        this.emptyCapacity = capacity;
    }

    private void makeSpace() {
        long currentTimeMillis = System.currentTimeMillis();
       // 计算离上次漏斗的时间
        long gap = currentTimeMillis - lastLeakingTime;
       // 计算离上次漏斗的时间到现在漏掉的水
        double deltaQuota = (int) gap * leakingRate;
        // 更新上次漏的水
        lastLeakingTime = currentTimeMillis;
        // 间隔时间太长，整数数字过大溢出 
       if (deltaQuota < 0) {
            emptyCapacity = capacity;
        }
        // 更新腾出的空间
        emptyCapacity += deltaQuota;
        // 超出最大限制 复原
        if (emptyCapacity > capacity) {
            emptyCapacity = capacity;
        }

    }

    boolean isActionAllowed(int quota) {
        makeSpace();
       // 如果腾出的空间大于需要的空间
        if (emptyCapacity >= quota) {
           // 给腾出空间注入流量
            emptyCapacity -= quota;
            return true;
        }
        return false;
    }
}

```

![image-20200405232439711](https://tva1.sinaimg.cn/large/00831rSTly1gdjb0mojzyj30v80lygp8.jpg)

Here we define an "empty capacity" to represent the freed space. It can also be calculated by the remaining water to calculate the space occupied by the water, which are two perspectives. But we use "empty capacity".

For the new traffic, we need to judge whether the Empty Capacity can accommodate these flows. If it can, reduce the size of the Empty Capacity. If it can't, reject it.

## Differences from the Token Bucket

* The token bucket puts tokens in at regular intervals, while the leaky bucket flows data at regular intervals.

* The naive implementation of the token bucket calculates the time that can handle the overflow request and blocks it, while the leaky bucket will reject the overflow traffic.

