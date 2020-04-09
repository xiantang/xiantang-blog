---
title: "漏桶算法的设计与实现"
date: 2020-04-05T01:37:56+08:00
lastmod: 2020-04-05T01:37:56+08:00
draft: false
tags: ["算法"]
categories: ["中文","算法"]
author: "xiantang"
---



## 什么是漏斗算法？

漏斗算法顾名思义采用一个漏斗来对流量进行限制。

因为漏斗下面有孔，所以会定时的漏水下去，然后我们可以将流量想象为从上边落入漏斗的水。

这样就会有两种情况，如果流量的注入漏斗的速度比漏斗的漏水的速度慢，漏斗就会处于一个空漏斗的状态，也就是没有超出负荷的状态。

第二种情况就是，如果流量注入漏斗的速度比漏斗快，那么漏斗就会渐渐的超出最大的容量，对于溢出的流量，漏斗会采用拒绝的方式，防止流量继续进入。

![image-20200405231856133](https://tva1.sinaimg.cn/large/00831rSTly1gdjauntjbcj30sy0j840y.jpg)

## 使用 Java 实现

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

我们这边定义了一个 empty capacity 的容量 表示腾出的空间。也可以通过以剩余的水来计算水占用的空间，这是两个角度来计算。但是我们使用的是empty capacity。

对于新来的流量，我们要判断是否Empty Capacity 能够容纳这些流量，如果能够容纳，就减少Empty Capacity的大小，不能的话就拒绝。



## 与令牌桶的区别

* 令牌桶是定时放入令牌，漏桶是定时流数据

* 朴素的令牌桶实现是对于溢出的请求计算出能够处理的时间进行阻塞，而漏桶则是会将溢出的流量拒绝。

  

