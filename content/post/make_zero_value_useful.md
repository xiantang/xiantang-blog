---
title: "Golang: 让你的零值更有用"
date: 2022-01-16T15:04:40+08:00
author: "xiantang"
# lastmod: 
# tags: []
# categories: []
# images:
#   - ./post/golang/cover.png
description:
draft: true
---


<!-- 
* 总是会先写一句话，同步背景和上下文
* 评论式写作引用一些大牛说的话
* 多一些有趣的跳转链接
* 在文章末尾推荐一些有趣的链接
* 先写提纲，再写内容 -->

> Make the zero value useful.
                        --Go Proverbs

让我们从 Golang blog 开始吧: [The zero value](https://go.dev/ref/spec#The_zero_value)
> 当内存被分配来存储一个值时，无论是通过声明还是调用 make 或 new ，并且没有提供明确的初始化，内存被赋予一个默认的初始化。这种值的每个元素都被设置为其类型的零值(zero value)：布尔值为 false，整数为 0，浮点数为0.0，字符串为 "" ，指针、函数、接口、slice、channel 和 map 为 nil。这种初始化是递归进行的，因此，举例来说，如果没有指定值，结构数组的每个元素都将被归零。

这样将一个值设置为零值对程序的安全性和正确性做了很大的保证，同样也能很好的保证程序的可读性与简单性。这也就是 Golang 程序员口中的 "让零值更有用 (Make the zero value useful)"。

## 零值 cheat sheet

| 类型 | 零值 |
| --- | --- |
| bool | false |
| int | 0 |
| float | 0.0 |
| string | "" |
| pointer | nil |
| function | nil |
| slice | nil |
| map | nil |
| channel | nil |

同时零值的初始化是递归的，因此，如果没有指定值，结构数组的每个元素都将被归零。

```golang
➜ gore --autoimport  
gore version 0.5.3  :help for help
gore> var a [10]int
gore> a
[10]int{
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
}
```

对于结构体也是如此，我们初始化一个引用 A 的 B 结构体，并且没有指定值，那么 B 的每个字段都将被归零。

```golang
➜ gore --autoimport
gore version 0.5.3  :help for help
gore> type A struct { i int; f float64 }
gore> type B struct { i int; f float64; next A }
gore> new(B)
&main.B{
  i:    0,
  f:    0.000000,
  next: main.A{
    i: 0,
    f: 0.000000,
  },
}
```

note:

* new: new(T) 返回一个指向新分配的T类型的 `零值` 的指针。
* 使用的工具为 [gore](https://github.com/x-motemen/gore)

## 零值的用法

上文已经介绍了什么是零值，这里我们来看看如何使用它们。

### sync.Mutex

这里有一个关于 sync.Mutex 的例子， sync.Mutex 被设计成不用显式地去初始化他就可以直接通过零值来使用。

```golang
package main

import "sync"

type MyInt struct {
        mu sync.Mutex
        val int
}

func main() {
        var i MyInt

        // i.mu is usable without explicit initialisation.
        i.mu.Lock()      
        i.val++
        i.mu.Unlock()
}
```

得益于零值的特性，Mutex 内部两个未导出的变量都会被初始化为零值。所以 sync.Mutex 的零值是一个未锁定的 Mutex。

```golang
// A Mutex is a mutual exclusion lock.
// The zero value for a Mutex is an unlocked mutex.
//
// A Mutex must not be copied after first use.
type Mutex struct {
 state int32
 sema  uint32
}
```

### bytes.Buffer

另外一个例子是 bytes.Buffer，它的零值是一个空的 Buffer。

```golang
package main

import "bytes"
import "io"
import "os"

func main() {
        var b bytes.Buffer
        b.Write([]byte("go go go"))
        io.Copy(os.Stdout, &b)
}
```

### json omitempty

### channel close

### not find in map

## 相关链接

* [Golang zero value](https://dave.cheney.net/2013/01/19/what-is-the-zero-value-and-why-is-it-useful)

## 文章推荐
