---
title: "Where is the GC root?"
date: 2020-04-06T01:37:56+08:00
lastmod: 2020-04-06T01:37:56+08:00
draft: false
tags: ["JVM"]
categories: ["English","JVM"]
author: "xiantang"
---

## What is GC Root

First of all, we know the marking algorithm, the JVM's marking algorithm can be understood as a reachability algorithm, so all reachability algorithms will have a starting point, and this starting point is the GC Root.

That is, it is necessary to find all living objects through the GC Root, and then all the remaining unmarked objects are the objects to be recycled.

![image-20200406124709630](https://tva1.sinaimg.cn/large/00831rSTly1gdjy7qsfg9j30w60cc47s.jpg)

## Characteristics of GC Root

* Objects that are alive at the current moment!



## Where is the GC Root

* References to objects in the GC heap in the currently active stack frames of all Java threads; in other words, the reference type parameters/local variables/temporary values of all currently being called methods.
* References to objects in the GC heap in some static data structures of the VM, for example, there are many such references in the Universe in the HotSpot VM.



Here is a question? Why do we need to set the GC root as the reference to the object in the GC heap in the currently active stack frame of all Java threads?

The reason is simple, the GC Root needs to ensure that the objects referred to are `alive`, and the objects in the current thread frame are alive at this moment.
