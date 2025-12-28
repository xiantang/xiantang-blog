---
title: "实现一个AtomicInteger"
date: 2020-04-06T16:33:34+08:00
tags: ["concurrency"]
categories: ["中文","java"]
draft: false

---


## 什么是 AtomicInteger

AtomicInteger 顾名思义是一个具有原子化操作的 Integer，与普通的 Integer 的区别是 AtomicInteger 采用一个 CAS 的方式使 Integer 的自增等操作变成原子化操作。

## 实现的之前需要了解的知识

首先我们先观察 AotmicInteger 的自增操作：

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

他采用了死循环，并且每次循环都获取最新的 value，通过这个值计算出自增后的值，使用 compareAndSet 来交换值，并且判断结果，如果是 true 就返回自增后的值，如果是 false 就进行重试，其实这就是一个典型的 CAS 操作。

并且这个 compareAndSet 操作，其实很简单，就是调用 unsafe 对象的 compareAndSwapInt

```java
public final boolean compareAndSet(int expect, int update) {
        return unsafe.compareAndSwapInt(this, valueOffset, expect, update);
}
```

compareAndSwapInt 就是根据当前对象的所需要 CAS 操作的成员的所在对象的 offset 来进行 CAS 的修改操作。

然后我们来看一下 get () 方法：

```java
private volatile int value;
public final int get() {
  return value;
}

```

就是返回 volatile 修饰的值，因为获取这个值是原子化行为，并且 volatile 能保证这个值是最新的。

## 我的实现

需要注意的是 `Unsafe.getUnsafe` 是无法直接调用的，因为他会判断是否是 BootStap 的类加载器或者是 Ext 类加载器，如果不是就抛出异常。

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
