---
title: "Singleton Pattern"
date: 2020-04-03T01:37:56+08:00
lastmod: 2020-04-03T01:37:56+08:00
draft: false
tags: ["Design Patterns"]
categories: ["English","Design Patterns"]
author: "xiantang"
---



# What is the Singleton Pattern?

The Singleton Pattern, also known as the Singleton, is a commonly used software design pattern and is one of the creational patterns.

In this design pattern, the class of the singleton object must ensure that only one instance exists.



# Pros and Cons

Pros: There is only one instance in memory, reducing memory overhead.

Cons: It violates the Single Responsibility Principle, and there is no interface, so it cannot be inherited.



# How to write the Singleton Pattern

## Single Thread

First, let's start with the singleton pattern in a single thread:

Let's clarify the idea first

The constructor of the singleton should be private, and getInstance is used to get the corresponding instance.

The singleton object exists in the class attribute to ensure that there is only one.

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

The singleton of a single thread is relatively easy to implement, but if there is multi-thread competition, this singleton pattern may cause duplicate creation.



## Multi-thread

We use the double-check method to ensure access under multi-threading:

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

But why use TwiceCheckSingleton and why are there two checks?

First, let's analyze check 1

In fact, if you delete the logic of check 1, the effect is the same as if you did not delete it, but why do it?

The main purpose is to improve performance, because if all threads need to get the existing singleton to enter this critical area, it may cause a drop in performance. Using this if can directly return the corresponding object to the request.

Let's analyze check 2

This operation is mainly to prevent duplicate object creation. You can imitate such a scenario, when threads concurrently enter the first check (because the instance has not been created yet)

```java
if (instance == null) { // check 1
  // 并发进入
  // 3个线程
  synchronized (sybObj) {
      instance = new TwiceCheckSingleton();
  }
}
```

Suppose 3 threads have entered the check1 statement block, one thread has entered check2 and created an object, the remaining three threads will enter the critical area in turn, and create three objects.

