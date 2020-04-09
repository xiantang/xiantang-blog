---
title: "什么是 Minor GC/Major GC"
date: 2020-04-06T01:37:56+08:00
lastmod: 2020-04-06T01:37:56+08:00
draft: false
tags: ["JVM"]
categories: ["中文","JVM"]
author: "xiantang"

---

## 什么是 Minor GC/Major GC

首先我们先科普一下JVM 经典的堆布局:

![image-20200406155036951](https://tva1.sinaimg.cn/large/00831rSTly1gdk3ifey1ej30lk08gwm5.jpg)

对于经典的 JVM heap 布局，有两个区域比较清晰，首先是Young 区,一般会来存放年轻的对象或者刚被创建没多久的对象。其次是 Old 区，也就是老年代，一般会来存放比较长寿的对象，或者从 young 区晋升的对象。

对于young 区 我们又有三个区域，一个是 Eden 区，还有两个大小相等的 Survivor 区。

新生的对象会在 Eden 区创建。

### Minor GC

此时如果新生的对象无法在 Eden 区创建（Eden 区无法容纳) 就会触发一次Young GC 此时会将 S0 区与Eden 区的对象一起进行可达性分析，找出活跃的对象，将它复制到 S1 区并且将S0区域和 Eden 区的对象给清空，这样那些不可达的对象进行清除，并且将S0 区 和 S1区交换。

但是这里会产生一个问题，Q:为啥会有两个 Survivor 区？

A: 因为假设设想一下只有一个 Survibor 区 那么就无法实现对于 S0 区的垃圾收集，以及分代年龄的提升。

### Major GC

发生在老年代的GC ，基本上发生了一次Major GC 就会发生一次 Minor GC。并且Major GC 的速度往往会比 Minor GC 慢 10 倍。



## 什么时候发生Major GC

既然我们已经知道了 Minor GC 是在 Eden 区快满的情况下才会触发

Q:那么 Major GC  呢?

A: 

1. 对于一个大对象，我们会首先在Eden 尝试创建，如果创建不了，就会触发Minor GC 
2. 随后继续尝试在Eden区存放，发现仍然放不下
3. 尝试直接进入老年代，老年代也放不下
4. 触发 Major GC 清理老年代的空间
   1. 放的下 成功
   2. 放不下 OOM



详见下图:

![image-20200406161521283](https://tva1.sinaimg.cn/large/00831rSTly1gdk486fnmtj310b0u04ig.jpg)

## 避免频繁的Full GC

* 避免定义过大的对象(数组)
* 避免将过大对象定义为静态变量