---
title: "What is Minor GC/Major GC"
date: 2020-04-06T01:37:56+08:00
lastmod: 2020-04-06T01:37:56+08:00
draft: false
tags: ["JVM"]
categories: ["Chinese","JVM"]
author: "xiantang"

---

## What is Minor GC/Major GC

First, let's popularize the classic heap layout of JVM:

![image-20200406155036951](https://tva1.sinaimg.cn/large/00831rSTly1gdk3ifey1ej30lk08gwm5.jpg)

For the classic JVM heap layout, there are two clear areas, the first is the Young area, which generally stores young objects or objects that have just been created. The second is the Old area, also known as the old generation, which generally stores longer-lived objects or objects promoted from the young area.

For the young area, we have three areas, one is the Eden area, and the other two are Survivor areas of equal size.

New objects are created in the Eden area.

### Minor GC

At this time, if the new object cannot be created in the Eden area (the Eden area cannot accommodate it), a Young GC will be triggered. At this time, the objects in the S0 area and the Eden area will be analyzed for reachability together, find out the active objects, copy them to the S1 area, and clear the objects in the S0 area and the Eden area, so that those unreachable objects are cleared, and the S0 area and the S1 area are swapped.

But there is a problem here, Q: Why are there two Survivor areas?

A: Because imagine that if there is only one Survivor area, then it is impossible to implement garbage collection for the S0 area and the promotion of generational age.

### Major GC

GC that occurs in the old generation, basically a Major GC will trigger a Minor GC. And the speed of Major GC is often 10 times slower than Minor GC.



## When does Major GC occur

Since we already know that Minor GC is triggered when the Eden area is almost full

Q: What about Major GC?

A: 

1. For a large object, we will first try to create it in Eden. If it cannot be created, it will trigger Minor GC 
2. Then continue to try to store it in the Eden area, and find that it still cannot be put down
3. Try to enter the old generation directly, and the old generation cannot put it down
4. Trigger Major GC to clean up the space in the old generation
   1. If it fits, it succeeds
   2. If it doesn't fit, OOM

See the image below:

![image-20200406161521283](https://tva1.sinaimg.cn/large/00831rSTly1gdk486fnmtj310b0u04ig.jpg)

## Avoid frequent Full GC

* Avoid defining overly large objects (arrays)
* Avoid defining overly large objects as static variables
