---
title: "GC root 在哪里？"
date: 2020-04-06T01:37:56+08:00
lastmod: 2020-04-06T01:37:56+08:00
draft: false
tags: ["JVM"]
categories: ["中文","JVM"]
author: "xiantang"
---

## 什么是GC Root

首先我们知道标记算法，JVM 的标记算法我们可以了解为一个可达性算法，所以所有的可达性算法都会有起点，那么这个起点就是GC Root。

也就是需要通过GC Root 找出所有活的对象，那么剩下所有的没有标记的对象就是需要回收的对象。

![image-20200406124709630](https://tva1.sinaimg.cn/large/00831rSTly1gdjy7qsfg9j30w60cc47s.jpg)

## GC Root 的特点

* 当前时刻存活的对象！



## GC Root 在哪里

* 所有Java线程当前活跃的栈帧里指向GC堆里的对象的引用；换句话说，当前所有正在被调用的方法的引用类型的参数/局部变量/临时值。
* VM的一些静态数据结构里指向GC堆里的对象的引用，例如说HotSpot VM里的Universe里有很多这样的引用。



这里有个问题? 为什么需要将GC root 设置为 所有Java线程当前活跃的栈帧里指向GC堆里的对象的引用? 

原因很简单，GC Root 需要确保引用所指的对象都是`活着的`,而当前线程 frame 中的对象，在这一时刻是存活的。

