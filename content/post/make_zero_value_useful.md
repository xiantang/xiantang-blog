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
> 当内存被分配来存储一个值时，无论是通过声明还是调用 make 或 new ，并且没有提供明确的初始化，内存被赋予一个默认的初始化。这种值的每个元素都被设置为其类型的零值(zero value)：布尔值为false，整数为0，浮点数为0.0，字符串为""，指针、函数、接口、片断、通道和地图为nil。这种初始化是递归进行的，因此，举例来说，如果没有指定值，结构数组的每个元素都将被归零。

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

## 如何让零值更有用？

## 相关链接

## 文章推荐
