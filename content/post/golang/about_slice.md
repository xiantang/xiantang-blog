---
title: "关于 Golang Slice 的一些细节"
date: 2021-12-21T01:37:56+08:00
lastmod: 2021-12-21T01:37:56+08:00
draft: false
tags: ["Golang"]
categories: ["Golang"]
author: "xiantang"
description: "Golang Slice 实现 Array append contains"

---

## 关于 Golang Slice 的一些细节

在 Golang 中，有两种数据类型：

一种是限定长度的数组，叫做 Array，另外一种是不限定长度的数组，叫做 Slice。

## 区分 Array 和 Slice

Array 和 Slice 的区别在于：

Array 是限定长度的，并且 Array 的长度是类型的一部分，因此 Array 的长度不能改变，而 Slice 可以改变长度。

Slice 是不限定长度的，可以使用 `make` 函数来创建。

`foo = make([]int, 5)`
并且 Slice 只是一个数据结构，内部有一个指针，指向数组的首地址，可以使用 `len` 函数来获取 Slice 的长度，也可以使用 `cap` 函数来获取 Slice 的容量。

下面会详细的介绍 Slice 的一些实现细节和特性。

## Slice 的实现与特性

上文已经提到 Slice 其实是一个数据结构，内部有一个指针，指向数组的首地址。
让我们来先简单看看 Slice 的实现吧：

我们先给出一个简单数据结构，用来演示 Slice 的实现：

```go
type slice struct {
        array unsafe.Pointer
        len   int
        cap   int
}
```

我们可以看到 Slice 的实现是个结构体，其中包含了三个字段：
第一个字段是指向底层数组的指针，第二个字段是 Slice 的长度，第三个字段是 Slice 的容量。
当你初始化一个长度为 5 的 Slice 的时候，他是这样的：

`foo = make([]int, 5)`

`foo = make([]int, 3, 5)`

![slice](https://divan.dev/images/slice2.png)

当你初始化一个为 nil 的 Slice 的时候，他是这样的：
`var foo []int`

```go
sliceHeader{
    Length:        0,
    Capacity:      0,
    ZerothElement: nil,
}
```

### slice header

上文的数据结构中可以看到，Slice 并不是一个真正的数组，而是一个数据结构，它的实现是个结构体，所以当我们在函数间传输 Slice 的时候，其实只是传输了一个 Slice 的 header。所以对于老练的 Gopher 来说，他们在函数间传输和 Channel 间传输的时候经常会提及 slice header。

我们可以讨论一下当 Slice 作为参数传递的时候会发生什么。

```go
package main

import (
	"fmt"
)

func main() {
 slice := []string{"a", "a"}

 func(slice []string) {
  slice = append(slice, "a")
  fmt.Print(slice)
 }(slice)
 fmt.Print(slice)
}
```

可以发现他运行的输出是：

```golang
[a a a][a a]
Program exited.
```

可以发现 Slice 作为参数被传递的时候，实际上和传递一个结构体一样，当你使用 append 之后赋给 slice 变量的时候只是把函数拷贝的值改了一下。
从这个例子可以看出，Golang 其实是 copy by value，而不是 copy by reference。当你传入一个结构体的时候，Golang 其实是把这个结构体拷贝了一份。

举一个另外一个例子，来体现 append 的效果以及：

```go
func main() {
 x := make([]string, 0, 6)

 func() {
  y := append(x, "hello", "world")
  fmt.Print(y)
 }()
 func() {
  z := append(x, "goodbye", "bob")
  fmt.Print(z)
 }()
}
```

```golang
[hello world][goodbye bob]
Program exited.
```

可以看出当你在 append 的时候，其实是会修改底层数组。但是我们发现其实如果对数组进行 append 了之后，其实不会对 x 进行修改，因为 x 其实并没有被修改。记住他只是 slice header，他的内容只取决于他的 len，cap 和 array 指针。

## Slice 的一些坑

### 切片的坑

Slice append 的时候，如果超出 cap 的长度，会去尝试 allocate 内存了，是尝试去当前容量两倍的内存，所以操作是非常昂贵的。。其实这个也不是很大的问题，因为 append 结束底层的数组就会被 GC 回收，但是如果有另外的 Slice 引用这个底层数组，就容易出问题。

```go
a := make([]int, 32)
b := a[1:16]
a = append(a, 1)
a[2] = 42
```

> Note：顺便说一下，append 只在 1024 以内通过加倍容量来增长分片，之后它将使用所谓的内存大小类来保证增长不超过~ 12.5%。为 32 字节的数组申请 64 字节是可以的，但是如果你的分片是 4GB，为增加一个元素再分配 4GB 是相当昂贵的，所以这是有道理的。

于是我们可以引出：
当你从一个非常大的数组里面尝试读取 3 个字符，会发现其实原始数据仍然是在内存里面

```go
var digitRegexp = regexp.MustCompile("[0-9]+")

func FindDigits(filename string) []byte {
    b, _ := ioutil.ReadFile(filename)
    return digitRegexp.Find(b)
}
```

笋干爆炸💥！！！

## string 竟然是 slice？

在 Golang 中，string 只是一串只读的 byte slice，所以你可以直接操作它，但是你不能修改它。

```go
func main() {
    const placeOfInterest = `中文`
    fmt.Printf("%v\n",len(placeOfInterest))
    
    for i := 0; i < len(placeOfInterest); i++ {
        fmt.Printf("%x ", placeOfInterest[i])
    }
    fmt.Printf("\n")
}
```

输出：

```golang
6
e4 b8 ad e6 96 87 

Program exited.
```

可以发现 string 的长度并不是 2，而是 6，因为 string 包含的是对应的 UTF-8 编码 (因为 Golang 代码是 UTF-8 编码的)，同时 string 是一串 byte slice。因为中文每个字符在 unicode 中都对应一个码位，一个码位占用 3 个 byte，所以 string 的长度是 6。

## 总结

以上就是一些常见的 slice 的使用。

## 相关阅读

* [Strings，bytes，runes and characters in Go](https://go.dev/blog/strings)
* [Arrays，slices (and strings)：The mechanics of‘append’](https://go.dev/blog/slices)
* [Slices from the ground up](https://dave.cheney.net/2018/07/12/slices-from-the-ground-up)
