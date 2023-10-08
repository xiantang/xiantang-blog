---
title: "Implementing an AtomicInteger"
date: 2020-04-06T16:33:34+08:00
tags: ["concurrency"]
categories: ["English","java"]
draft: false

---


## What is AtomicInteger

As the name suggests, AtomicInteger is an Integer with atomic operations. The difference between AtomicInteger and a regular Integer is that AtomicInteger uses a CAS method to make Integer's increment and other operations atomic.

## Knowledge needed before implementation

First, let's look at the increment operation of AtomicInteger:

```java
public final int incrementAndGet() {
         for (;;) {
          int current = get();
          int next = current + 1;
          if (compareAndSet(current, next))
             return next;
          }
 }
```

It uses a loop, and each time it loops, it gets the latest value, calculates the value after incrementing, uses compareAndSet to swap values, and checks the result. If it's true, it returns the value after incrementing. If it's false, it retries. This is a typical CAS operation.

And this compareAndSet operation is actually very simple, it just calls the compareAndSwapInt of the unsafe object

```java
public final boolean compareAndSet(int expect, int update) {
        return unsafe.compareAndSwapInt(this, valueOffset, expect, update);
}
```

compareAndSwapInt performs the CAS modification operation based on the offset of the object where the member that needs the CAS operation is located.

Then let's look at the get() method:

```java
private volatile int value;
public final int get() {
  return value;
}

```

It just returns the value modified by volatile, because getting this value is an atomic action, and volatile can ensure that this value is the latest.

## My implementation

It should be noted that `Unsafe.getUnsafe` cannot be called directly, because it will determine whether it is a BootStap class loader or an Ext class loader. If not, it will throw an exception.

```java
public class AtomicInteger {
    private static final Unsafe unsafe = getUnsafeInstance();

    private static long offset;

    static {
        try {
            offset = unsafe.objectFieldOffset(AtomicInteger.class.getDeclaredField("value"));
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        }
    }


    private volatile int value;

    AtomicInteger(int value) {
        this.value = value;
    }

    //通过反射获取对应实例
    private static Unsafe getUnsafeInstance() {
        Field unsafeInstance;
        try {
            unsafeInstance = Unsafe.class.getDeclaredField("theUnsafe");
            unsafeInstance.setAccessible(true);
            return (Unsafe) unsafeInstance.get(Unsafe.class);
        } catch (NoSuchFieldException | IllegalAccessException e) {
            e.printStackTrace();
        }
        return null;
    }

    int incrementAndGet() {
        int curr;
        int next;
        do {
            curr = get();
            next = curr + 1;
        } while (!unsafe.compareAndSwapInt(this, offset, curr, next));

        return get();
    }

    public int get() {
        return value;
    }
}

```

Sure, please provide the Markdown content you want to translate.
