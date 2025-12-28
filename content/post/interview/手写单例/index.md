---
title: "单例模式"
date: 2020-04-03T01:37:56+08:00
lastmod: 2020-04-03T01:37:56+08:00
draft: false
tags: ["设计模式"]
categories: ["中文","设计模式"]
author: "xiantang"
---



# 单例模式是什么?

单例模式，也叫单子模式，是一种常用的软件设计模式，属于创建型模式的一种。

在这个设计模式中，单例对象的类必须保证只有一个实例存在。



# 优缺点

优点: 内存中只有一个实例，减少内存开销。

缺点: 违背单一职责原则，并且没有接口，不能继承。



# 单例模式怎么写

## 单线程

首先我们从单线程的单例模式开始实现:

先厘清一波思路

单例的构造器应该为 private ,采用 getInstance 来获取对应的实例。

单例对象存在于类属性中，保证只有一个。

```java
class Singleton {
    private static Singleton instance = null;
    private Singleton() {
    }

    static Singleton getInstance() {
      if (instance == null) {
        instance = new Singleton();
      }
      return instance;
    }
}
```

单线程的单例比较容易实现，但是如果存在多线程竞争，这个单例模式就可能会造成重复创建。



## 多线程

我们采用的是双重检验的方式来确保多线程下的访问:

```java
class TwiceCheckSingleton {
    private static TwiceCheckSingleton instance = null;
    private static final Object sybObj = new Object();

    private TwiceCheckSingleton() {
    }

    static TwiceCheckSingleton getInstance() {
        if (instance == null) { // check 1
            synchronized (sybObj) {
                if (instance == null) { // check 2
                    instance = new TwiceCheckSingleton();
                }
            }
        }

        return instance;
    }
}

```

但是为什么要使用 TwiceCheckSingleton 并且为啥有两次检验呢?

首先我们来分析一下 check 1

其实如果你将check 1 这段代码逻辑删除，和没有删除的效果是一样的，但是为什么要这样做呢?

主要的目的是提高性能，因为如果所有的线程需要获取已经存在的单例都需要进入这个临界区的话，可能会造成性能的下降，使用这个 if 可以将获取的请求直接返回对应的对象。

再来分析一下 check 2

这个操作主要是防止重复创建对象。可以模仿一下这样的场景,当线程并发的进入第一个check (因为实例还没有创建)

```java
if (instance == null) { // check 1
  // 并发进入
  // 3个线程
  synchronized (sybObj) {
      instance = new TwiceCheckSingleton();
  }
}
```

假设有3个线程进入了check1 语句块，一个线程已经进入了check2 并且创建完对象，剩下三个线程会依次进入临界区，并且创建三次对象。















