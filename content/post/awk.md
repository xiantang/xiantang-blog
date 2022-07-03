---
title: "使用二八法则省力地学习 awk"
date: 2022-06-29T22:14:09+08:00
author: "xiantang"
lastmod:
tags: ["中文","软技能","awk"]
categories: ["中文","awk"]
images:
  - ./post/awk.png
description:
draft: false
---


<!-- 
* 总是会先写一句话，同步背景和上下文
* 评论式写作引用一些大牛说的话
* 多一些有趣的跳转链接
* 在文章末尾推荐一些有趣的链接
* 先写提纲，再写内容 -->

> 篇幅只占20%、然而有效性却达到80%  -二八法则

# 本文你能学到什么？

在本文中，我们将学习到如何使用二八法则来省力轻松学习 linux 文本处理命令 awk。读完本文你就会学习到一种快速学习的方法，
以及使用 awk 来处理文本和 stdout。

最近在学习 awk 发现真的有很多细节，没办法一开始就抓住最重要的部分，被繁杂的语法所困扰，比较难懂。
于是使用从《软技能-代码之外的生存指南》中学习的二八法则，来实践学习一下 awk 的基本用法，发现效果十分不错。
本文就介绍一下我是如何使用二八法则学习 awk 的。

## 什么是二八法则？

在文章的开篇中有提到 "篇幅只占20%、然而有效性却达到80%"，叫做 "帕累托法则"。指出约有 20% 的因素可以影响 80% 的结果。
对于学习技术也是十分的适用，用得最多的 20% 的技术知识点，可以完成 80% 的技术工作。也就是说其实我们只需要专注最常用的
case 来针对性学习，防止真正重要的内容会被埋没在细枝末节中。

## 如何利用二八法则来学习？

既然二八法则这么好用那如何来实践呢？ 《软技能-代码之外的生存指南》 主要总结了 10 步，也就是学习一个新的技术可以通过下面十步来完成：

- 第一步： 如何开始： 想要用起来 需要哪些基本知识？
- 第二步：学科范围：学的东西有多少大？我要怎么做？
- 第三步：需要了解基本的用户案例，和常见问题，知道学哪 20% 满足 80% 应用场景 
- 第四步：寻找资源
- 第五步：定义目标 
- 第六步： 筛选资源
- 第七步：开始学习 浅尝即止
- 第八步：动手操作 边学边玩
- 第九步：全面掌握，学以致用
- 第十步：好为人师

我们可以将这 10 步分为两大块
* 第一块 第一步到第六步，只需要从头到尾执行一次
* 第二块 第七步到第十步，需要反复执行

其中第一块查找筛选输入资源，定义目标中需要注意的是：

找到**实际的应用的主要用途**是哪些：
例如 sed 你会发现他的主要的应用的 case 是对文本和流数据行的增删改查。对于这些 common case 
你可以通过粗浅的扫一下相关的资料来了解到。 如果不知道如何有效的获取信息，可以看这一篇我的文章
[我是如何获取知识与信息的](/post/softskills/how_do_i_acquire_knowledge_and_information/)

定义出一个**可执行的目标**： 
你需要定义一个可执行的目标，比如对于 sed 我需要把 `tldr sed` 中所有用例重写一遍。对于`awk` 我的目标就是
使用 `awk` 来查找 yaml 中的某个字段的值。

筛选**足够达成目标所需的资料**：
当你通过搜索引擎到一些比较好的资料时候，你就可以通过阅读大纲等筛选出阅读之后能让你达到目标的资料，也就是最常见用途的资料虽然可能比较粗略，
但是之后在你实践的时候会更加精确的在其中找到真正你需要的资料。

第二块**边查文档边实践，输出见解**：
其实我对于如何快速学习技术的方法一直都是动手去做，多去实践。刚毕业的时候我很喜欢对于一个技术知识点采用"从封面到封底"的方式去学习，
但是随着时间越来越少，已经没有精力把一本书从头到尾的精读完了。

于是按照边查文档边实践的方式来学习的方式效率会更高，同时这也符合学习金字塔的思想。

![学习金字塔](/image/the_cone_of_learning.png)

对于一个知识点如果你只采用读的方式去学习，那你只能吸收到 10% 的内容，但是你采用教学和玩的方式去学习，你可以吸收到 90% 的内容。
举个很简单的例子，我当时高中的时候玩炉石传说，里面经典卡牌有 300+ 张，我却能够说出 90% 的牌的身材和效果，其实我没有刻意的去记住
只是因为我玩的时候比较喜欢玩，所以我就把这些卡牌都学习了。

所以很重要一点就是在**学习的时候采用玩的方式**，去实践而不是捧读文档。
同样**教学是更好的学习**，因为你能在同时巩固和确定你的知识点的逻辑是正确的，我输出这篇文章也是为了更好的巩固关于二八法则与 awk 这些知识点。

对于这比较有用的 20% 的知识点采用实践的方式去学习之后，当你正在实践的时候，遇到一些偏门的 feature 你就可以通过查阅文档的方式，更加精确得使用
这些 feature 避免了你在繁杂的细节中迷失。

下面我会举两个实例来说明这个方法：

# 学习 awk

首先我们通过浅读文档了解到 awk 是一个什么样的工具：

`Awk is an extremely versatile programming language for working on files. ` 

awk 其实是一种用于处理文本的编程语言，这就能解释当你从 stackoverflow 上尝试解决文本处理问题的时候，
很多回答给出 awk 的示例没有那么简单明了，原因也就是他是一门编程语言，并不像 grep 一样只需要添加几个命令行参数就可以
查找文本。

## 寻找最常用的用途

我这边是使用 `tldr` 来查找这个命令的最常用的用途，`tldr` 通过实际示例简化深受欢迎的 `man` 页面。
他的输出如下：

```
awk

A versatile programming language for working on files.
More information: https://github.com/onetrueawk/awk.

- Print the fifth column (a.k.a. field) in a space-separated file:
awk '{print $5}' filename

- Print the second column of the lines containing "foo" in a space-separated file:
awk '/foo/ {print $2}' filename

- Print the last column of each line in a file, using a comma (instead of space) as a field separator:
awk -F ',' '{print $NF}' filename

- Print all lines where the 10th column value equals the specified value:
awk '($10 == value)'

- Sum the values in the first column of a file and print the total:
  awk '{s+=$1} END {print s}' filename
...
```

通过这些示例我就能知道 awk 的常用用途有哪些，以及就是哪些语法和参数是最重要的。

用途主要有：
1. 打印文件中的某一列
2. 根据某个值找到对应的行
3. 将某一行根据某个 field separator 切分成多个字段
4. 打印满足某个条件的行

根据例子中我们能了解到 -F 这个参数是比较有用的， 同时 `print` 关键词和 `$` 开头的变量也比较有用。

我们心中也产生了一些疑问：
* `'{print $5}'` 这种语法指的是什么？
* `'/foo/ {print $2}'` 为什么在空格分隔的文件中打印包含“foo”的行的第二列? 

## 找到学习资源

带着这些问题和了解到的常用 case 我们就可以通过搜索引擎来找到相关的资源：

- https://www.eriwen.com/tools/awk-is-a-beautiful-tool/ 一篇关于 awk 的短博客，讲了一些哲学
- `man awk`  man 手册
- `tldr awk` tldr awk
- https://www.gnu.org/software/gawk/manual/gawk.html#Getting-Started 
- https://www.geeksforgeeks.org/awk-command-unixlinux-examples/ tutorial
- https://www.runoob.com/linux/linux-comm-awk.html tutorial
- [Summary of AWK Commands](https://www.grymoire.com/Unix/Awk.html#toc-uh-13) 简明介绍
- https://sparky.rice.edu//~hartigan/awk.html  如何使用 awk

我们找到了 8 个相关资源，其中包含很长的用户手册，但是不必担心，我们不会读完它，只是扫一下结构知道哪些章节
包含哪些内容就够了。后面我会对它进行筛选。


## 设定目标

然后就是设定学习目标，注意这个目标一定要是 **可执行的**，如果你使用过 OKR 或者 GTD，那么你就会基本了解是怎么样的。
类似 OKR 的 key result 就是对于这个目标的一个可衡量的结果，或者 GTD 的执行清单的每一个小 task，都是可执行的，可以衡量的。

这个例子中我主要设定了 3 个目标：

* 首先就是对于 tldr 中的示例需要保证自己通过手写能写出来，因为这个示例是大多数常用的 case
* 其次是格式化输出下面的学生的总分平均分：
    ```
    Marry   2143 78 84 77
    Jack    2321 66 78 45
    Tom     2122 48 77 71
    Mike    2537 87 97 95
    Bob     2415 40 57 62
    ```
  结果会是这样的
  ```
  NAME    NO.   MATH  ENGLISH  COMPUTER   TOTAL
  ---------------------------------------------
  Marry  2143     78       84       77      239
  Jack   2321     66       78       45      189
  Tom    2122     48       77       71      196
  Mike   2537     87       97       95      279
  Bob    2415     40       57       62      159
  ---------------------------------------------
  TOTAL:       319      393      350
  AVERAGE:     63.80    78.60    70.00
  ```
* 最后是通过 awk 来找到 yaml 中某一个字段的值，这个难度较大但是比较有意思，[Parse a YAML section using shell](https://unix.stackexchange.com/questions/608137/parse-a-yaml-section-using-shell)


可以看到这三个目标都是可以执行的，同时很好衡量结果。
## 过滤学习资源

设定了目标之后，我们就可以根据目标来筛选出相关的资源：

我筛选出以下资源：
[awk is a beautiful tool](https://www.eriwen.com/tools/awk-is-a-beautiful-tool/)，man page,
[执行 awk 脚本](https://www.grymoire.com/Unix/Awk.html#toc-uh-2),[awk 语法](https://www.grymoire.com/Unix/Awk.html#toc-uh-13),
[awk 正则表达式 && 条件表达式](https://www.grymoire.com/Unix/Awk.html#toc-uh-11)


## 浅读筛选出的资料

首先我们可以浅读以下筛选出的资料：

发现 awk 其实每次只会操作一个记录(record)，这个记录默认是一行。同时会提取每一行中通过空格（默认）分隔的字符串作为每一个字段(field)。

这样就能解答 `'{print $5}'` 中 $5 其实就是每一行通过空格分隔的第 5 个字段。并且使用 -F 就能将分隔用的字符串从空格替换为指定的字符串。

`awk -F ','` 这就是使用逗号来分隔字段。


## 学以致用

### 完成 tldr 中的示例的复现
这个时候你可以打开你的命令行开始把玩 `awk`， 你会发现 

`awk '/foo/ {print $2}' filename` 这样的语法很有意思。

通过查阅文档你发现其实 /foo/ 中的 可以换成各种正则表达式：

对于：

```
Marry	2143	78	84	77
Jack	2321	66	78	45
Tom	2122	48	77	71
Mike	2537	87	97	95
Bob	2415	40	57	62
```
可以使用这个方式打印出包含 /Bob/ 的行
`awk '/Bob/ {print $0}'  sheet` 

使用 `awk '/m$/'` 能打印出包含 m 结尾的字段的行，也就是包含 Tom 的行。

通过阅读 man 手册中关于正则表达式的一章 `Regular expressions`

`awk '/m$/' {print $0}` 其实是 `awk $0 ~ '/m$/ {print $0}'` 的简写。

表示当输入的记录（默认为行）的时候，如果字段（fields）匹配这个表达式就打印出当前行。


所以我们会发现 `tldr` 中对于这个case是错误的
```
foo bar ggg
bar foo ggg
```

```
- Print the second column of the lines containing "foo" in a space-separated file:
awk '/foo/ {print $2}' filename
```

正确的应该是 `awk '$2 ~ /foo/ {print $2}'`，当 `$2 ~ /foo/` 匹配的时候会赋值成 1，不匹配的时候会赋值成 0。
也就是当匹配的时候，这处理这一行记录就会变成 `awk '1 {print $2}` ，不匹配就会变成 `awk '0 {print $2}` 。


### 实现格式化学生的成绩

要实现将学生的成绩格式化，需要引入 `awk` 的脚本，可以从筛选出的资料中阅读。
总结一下就是 -f 可以指定 awk 的脚本，文件的第一行需要是 `#!/bin/awk -f`， 之后的脚本就是 `awk` 的脚本。

awk 的关键字也可以在筛选出的文档中找到，边玩边看文档，真的能很有效地找到重要的资源。

[基础结构](https://www.grymoire.com/Unix/Awk.html#toc-uh-1)

```awk
BEGIN { print "START" }
/foo/ { print         }
END   { print "STOP"  }
```

从上面的例子可以看出 awk 比较重要的是，该模式指定了以读取的每一行作为输入执行的行为。
如果前边的表达式为真，则执行 `{ print }` 中的代码。
如果前面没有表达式，就默认匹配到每一行中的内容。
另外 BEGIN 和 END 也是另外两个重要的模式。
如你所料，这两个词指定了在读取任何行之前和读取最后一行之后要执行的操作。

了解这个就能实现一个这个小目标了：

```awk
#!/bin/awk -f
BEGIN {
math=0
english=0
art=0
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", "Name", "No.", "MATH", "ENGLISH","ART","TOTAL"
}
{
	math+=$3
	english+=$4
	art+=$5
	cnt+=1
	total=$3+$4+$5
	sum+=total
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", $1, $2,$3,$4,$5,total
}
END  {
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", "TOTAL","", math,english,art,total
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", "AVG","", math/cnt, english/cnt,art/cnt,sum/cnt
}
```

### awk 来找到 yaml 中某一个字段的值

Stackoverflow 上这个回答令人摸不到头脑: 
```
something:
 - whatever:
   - something
 - toc: 4
 - body: assets/footer.html
pkg:
 - pkg_a_1:
   - Shass
   - AJh55
   - ASH7
 - pkg_b_1:
   - Kjs6
   - opsaa
other:
morestuff:
 - whatever
```

需要拿到 pkg_a_1 的值，输出这样：
```
pkg_a_1 Shass
pkg_a_1 AJh55
pkg_a_1 ASH7
pkg_b_1 Kjs6
pkg_b_1 opsaa
```

所给到的解答是 `awk '/^[^ ]/{ f=/^pkg:/; next } f{ if (sub(/:$/,"")) pkg=$2; else print pkg, $2 }' file`

刚看到答案一脸懵逼是吧，我们将输入拆分一下：

* `/^[^ ]/` 是匹配所有非空行。
* `f=/^pkg:/`是在当前行做匹配，如果匹配到了，f 就会变成 1，否则 f 就会变成 0。
  ```
  xiantang@ubuntu:~$ awk '/^[^ ]/{ f=/^pkg:/;print f}' ymal
    0
    1
    0
    0
  ```
* next 指的是跳过当前行，继续解析下面的行。
* 下面的 f 是一个标志，如果 f 为 1，执行下面的行为。
* 最后的赋值操作就不解释了。

如果我想要读取 something.body 的值，例如这样的输出

`something.body assets/footer.html`

可以使用 `awk '/^[^ ]/{ f=/^something/;sub(/:/,".",$0);prefix=$0;  next } f{ b=/body/;} f&&b{printf "%s%s %s\n", prefix,$2,$3}' ymal`

`something.body: assets/footer.html`

这样我们就完成了对于 awk 的三个小目标，注意在实践的时候要一边实践一边回味文档，多去尝试一下不同的行为
当你去尝试了，才是真正的学会了。


# 总结

本文讲解了如何找到资料以及通过设定目标的方式来筛选资料，以及如何通过实践来快速的学习知识。
并且举了个学习 awk 的例子来实践这个方法，这个方法适用于 80% 的学习场景，别忘了学有所成之后分享出来哦！