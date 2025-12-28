---
title: "Java 集合扩容"
date: 2018-12-07T01:37:56+08:00
lastmod: 2018-12-07T01:37:56+08:00
draft: false
tags: ["Java"]
categories: ["Java"]
author: "xiantang"

---

## 集合扩容

### ArrayList

对于 ArrayList 他默认的容量为 10，所以如果需要对 ArrayList 进行大数据量的处理的时候的话，就需要使用显式制定容量的方式进行处理。这样可以减少不必要的扩容操作。

主要是因为 ArrayList 的扩容操作需要额外开辟空间，他采用的是 Arrays.copyOf 的方式进行拷贝：

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

Arrays.copyOf 的方式是采用开辟空间再复制的方式，很有可能会造成 OOM。

### HashMap

HashMap 的默认容量为 16，并且他的容量一定是 2 的幂。

如果指定的容量不是 2 次幂，他也会求出距离当前容量最近的 2 次幂。

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

至于为什么是 2 的幂，是因为 SUN 的大师们发现，让容量为 2^n 时候，`(length - 1) & hash` 快于模运算。

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

使用%时间：16
使用&时间：9

我们以 length 为 16 为例

当我们的 hash 为17时

原因是因为 16 - 1 的二进制为 01111 并且 17 的二进制为 1 0001  
 我们只需要计算低位，高位全部舍弃，低位进行 & 运算，得出结果是 1 与 17 % 16 的结果完全相同。
