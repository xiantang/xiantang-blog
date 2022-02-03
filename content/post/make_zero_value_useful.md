---
title: "Golang: 让你的零值更有用"
date: 2022-01-16T15:04:40+08:00
author: "xiantang"
# lastmod: 
tags: ["中文", "Golang"]
categories: ["Golang"]
images:
  - ./post/make_zero_value_useful.png
description: Golang 使用零值来让你的代码更简洁，其中介绍了 Golang json 零值，Golang map 零值等。
draft: false
---


<!-- 
* 总是会先写一句话，同步背景和上下文
* 评论式写作引用一些大牛说的话
* 多一些有趣的跳转链接
* 在文章末尾推荐一些有趣的链接
* 先写提纲，再写内容 -->

> Make the zero value useful。
                        --Go Proverbs

让我们从 Golang blog 开始吧：[The zero value](https://go.dev/ref/spec#The_zero_value)
> 当内存被分配来存储一个值时，无论是通过声明还是调用 make 或 new，并且没有提供明确的初始化，内存被赋予一个默认的初始化。这种值的每个元素都被设置为其类型的零值 (zero value)：布尔值为 false，整数为 0，浮点数为 0.0，字符串为 `""`，指针、函数、接口、slice、channel 和 map 为 nil。这种初始化是递归进行的，因此，举例来说，如果没有指定值，结构数组的每个元素都将被归零。

这样将一个值设置为零值对程序的安全性和正确性做了很大的保证，同样也能很好的保证程序的可读性与简单性。这也就是 Golang 程序员口中的“让零值更有用 (Make the zero value useful)”。

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

note：

* new：new(T) 返回一个指向新分配的 T 类型的 `零值` 的指针。
* 使用的工具为 [gore](https://github.com/x-motemen/gore)

## 零值的用法

上文已经介绍了什么是零值，这里我们来看看如何使用它们。

### sync.Mutex

这里有一个关于 sync.Mutex 的例子，sync.Mutex 被设计成不用显式地去初始化他就可以直接通过零值来使用。

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

### JSON omitempty

JSON 接收器也接受 `omitempty` 这个 flag，当输入的字段是 `零值` 时，接收器会忽略这个字段。

```golang
➜  gore --autoimport          
gore version 0.5.3  :help for help
gore> type Person struct {
.....         Name string `json:"name"`
.....         Age  int    `json:"age"`
.....         Addr string `json:"addr,omitempty"`
..... }
gore> p1 := Person{
.....             Name: "taoge",
.....             Age:  30,
.....     }
main.Person{
  Name: "taoge",
  Age:  30,
  Addr: "",
}
gore> data, err := json.Marshal(p1)
...
gore> string(data)
"{\"name\":\"taoge\",\"age\":30}"
```

### channel close

在[《Channel Axioms》](https://dave.cheney.net/2014/03/19/channel-axioms)中，也有一条与零值相关的规则，当 channel 关闭时，对被关闭的 channel 做<- 操作，总是立即返回 `零值`。

```golang
package main

import "fmt"

func main() {
         c := make(chan int, 3)
         c <- 1
         c <- 2
         c <- 3
         close(c)
         for i := 0; i < 4; i++ {
                  fmt.Printf("%d ", <-c) // prints 1 2 3 0
         }
}
```

解决上述问题的正确的方式是使用 for loop：

```golang
for v := range c {
         // do something with v
}

```

### map 中未找到对应 key 的 value

对于一个 map，如果没有找到对应的 key，那么这个 map 会返回对应类型一个零值。

```golang
➜ gore --autoimport
gore version 0.5.3  :help for help
gore> a := make(map[string]string)
map[string]string{}
gore> a["123"] = "456"
"456"
gore> a["000"]
""
```

解决这个问题的方法是返回多个值：

```golang
gore --autoimport
gore version 0.5.3  :help for help
gore> a := make(map[string]string)
map[string]string{}
gore> c,ok := a["000"]
""
false
```

对于不存在的 key，ok 的 value 将会变成 false。

## 总结

以上就是关于 `零值` 的一些经验总结。希望大家在设计代码的时候能够将 `零值` 更好的用起来，利用 `零值` 提供的特性来初始化一些变量。

## 相关链接

* [Golang zero value](https://dave.cheney.net/2013/01/19/what-is-the-zero-value-and-why-is-it-useful)
* [《Channel Axioms》](https://dave.cheney.net/2014/03/19/channel-axioms)
* [Go REPL](https://github.com/x-motemen/gore)

## 文章推荐

最后最后和大家分享一些最近在看的好文，想过用周刊的方式发送但是因为看的比较零散，就放在每篇博文的最后，希望大家能够收获。

* [为什么我们不生小孩](https://shuxiao.wang/posts/why-no-new-baby/)一些关于生小孩的思考
* [《The Tail At Scale》论文详细解读](https://blog.csdn.net/LuciferMS/article/details/122522964)
* [编写可维护的 Go 代码](https://jogendra.dev/writing-maintainable-go-code)很多观点让我在实践之后感受到共鸣，代码写出来一遍，但是会被读上百遍，所以编写可维护的代码很重要。
* [Golang 并发编程进阶 talk](https://go.dev/blog/io2013-talk-concurrency) 分享者提供了实际并发问题的，然后给出了自己的一些解决方案。非常受益。
* [pprof 图解](https://github.com/google/pprof/blob/master/doc/README.md#interpreting-the-callgraph)终于会看 pprof 了。
