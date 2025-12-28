---
title: "Java Collection Expansion"
date: 2018-12-07T01:37:56+08:00
lastmod: 2018-12-07T01:37:56+08:00
draft: false
tags: ["Java"]
categories: ["Java"]
author: "xiantang"

---

## Collection Expansion

### ArrayList

The default capacity of ArrayList is 10, so if you need to handle large amounts of data with ArrayList, you need to use the method of explicitly specifying the capacity. This can reduce unnecessary expansion operations.

The main reason is that the expansion operation of ArrayList requires extra space, and it uses the Arrays.copyOf method for copying:

```java
private void grow(int minCapacity) {
  // overflow-conscious code
  int oldCapacity = elementData.length;
  int newCapacity = oldCapacity + (oldCapacity >> 1);
  if (newCapacity - minCapacity < 0)
    newCapacity = minCapacity;
  if (newCapacity - MAX_ARRAY_SIZE > 0)
    newCapacity = hugeCapacity(minCapacity);
  // minCapacity is usually close to size, so this is a win:
  elementData = Arrays.copyOf(elementData, newCapacity);
}
```

The Arrays.copyOf method uses the method of allocating space and then copying, which is very likely to cause OOM.

### HashMap

The default capacity of HashMap is 16, and its capacity must be a power of 2.

If the specified capacity is not a power of 2, it will also find the power of 2 closest to the current capacity.

```java
    /**
     * Returns a power of two size for the given target capacity.
     */
    static final int tableSizeFor(int cap) {
        int n = cap - 1;
        n |= n >>> 1;
        n |= n >>> 2;
        n |= n >>> 4;
        n |= n >>> 8;
        n |= n >>> 16;
        return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
    }
```

The reason why it is a power of 2 is because the masters of SUN found that when the capacity is 2^n, `(length - 1) & hash` is faster than modulo operation.

```java
    @Test
    public void testModAndWith() {
        long currentTimeMillis = System.currentTimeMillis();
        for (int i = 0; i < 10000000; i++) {
            int i1 = 6666 % 16;
            assertEquals(10, i1);
        }
        long l = System.currentTimeMillis() - currentTimeMillis;
        System.out.println("使用%时间: " + l);
        long currentTimeMillis1 = System.currentTimeMillis();
        for (int i = 0; i < 10000000; i++) {
            int i1 = 6666 & (16-1);
            assertEquals(10, i1);
        }
        long l1 = System.currentTimeMillis() - currentTimeMillis1;
        System.out.println("使用&时间: " + l1);

    }
```

Use % time: 16
Use & time: 9

We take length as 16 as an example

When our hash is 17

The reason is because the binary of 16 - 1 is 01111 and the binary of 17 is 1 0001  
 We only need to calculate the low bit, discard all the high bits, and perform & operation on the low bit, the result is 1 and the result of 17 % 16 is exactly the same.
