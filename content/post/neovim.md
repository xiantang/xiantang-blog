---
title: "使用 neovim 作为 PDE(个性化开发环境)"
date: 2022-10-29T20:45:20+08:00
author: "xiantang"
# lastmod: 
tags: ["neovim"]
categories: ["neovim"]
images:
 - ./post/neovim.png
description:
draft: false
---


<!-- * 总是会先写一句话，同步背景和上下文 -->
<!-- * 本文你能学习到什么 -->
<!-- * 评论式写作引用一些大牛说的话 -->
<!-- * 多一些有趣的跳转链接 -->
<!-- * 在文章末尾推荐一些有趣的链接 -->
<!-- * 先写提纲，再写内容 -- -->

本文不会告诉你如何一步一步地配置 neovim，而是告诉你一些关于 PDE 的 "道", 不是具体实践的 "术"。

## 介绍什么的 neovim 与 PDE

看到 TJ 的youtube 介绍了 neovim 作为 PDE 的使用，感觉很有意思，于是就自己也尝试了一下，感觉还不错，所以就记录一下。

### 什么是 neovim

neovim 是一个 vim 的分支，vim 是一个文本编辑器，neovim 是 vim 的一个分支，它的目标是提供一个更好的 vim，而不是 vim 的替代品。

neovim 和 vim 有什么区别呢？ 
区别在于 neovim 重构了 vim 的代码，在兼容 vimscipt 的基础上，支持了 lua 脚本作为配置语言。同时 neovim 在 Github 上比 vim 的社区更加活跃。neovim 有更用的 lsp 服务器，可以理解 neovim 是 vim 的超集。


### 什么是 PDE

PDE 是个性化开发环境，指的是在满足基础的开发需求的基础上，用户能够对自己使用的开发环境做一些脚本化，自定义化的行为, 从而提升用户的开发体验和效率。


当你不断地能够解决你开发环境中的痛点，你的开发效率会越来越高，你的开发体验会越来越好，这就是 PDE 的魅力所在。

你也能从中不断学到新的东西，在这个过程中，你也会从中获得成就感。


## 需要满足的基础需求


定义你的 PDE 需要满足的基础需求，比如：

* 高亮
* lsp
  * 基础的重构 rename
  * 快速跳转
* lint
* 代码建议
* code snippet
* debugging
* 快速找到最近文件

因为只有满足的这些最基础的需求，你才能保证你不会返回到你的老的编辑器中。在此之上不断地找到你自己的痛点，然后解决它，你就会越来越快越来越来越掌握这个工具。

## 个性化的需求


有些时候我总有一些有趣的需求, 我就简单举一个例子吧:

比如说我很多时候会同时修改多个项目在 vim 中, 但是 nerdtree 的 NERDTreeFind 只会从当前树里面找，并且树的根目录总是错的，我的需求是想要在 nerdtree 的 bookmarks 里面找到这个文件，并且根目录是第一个匹配到的 bookmark.



![show off](https://user-images.githubusercontent.com/34479567/204140677-0c11c2c8-cca7-44d2-8971-12632e3f0874.gif)

可以参考我的实现:

https://github.com/xiantang/nvim-conf/blob/dev/lua/nerdtree.lua

基本上所有你想要的功能都可以通过修改 lua 来达成, 或者通过使用 nvim 系列的插件。

1. 比如说快速唤出一个 terminal 或者一个笔记 txt
2. 添加一些自定义的 snippet
3. 等等... 

## 更好的配置管理

其实大家在使用 neovim 来制作自己的 PDE 的时候会发现，你很容易就会把自己的 neovim 搞坏，因为你的配置中会有很多插件，而这些插件是很多时候不兼容的。所以下面两点至关重要：

1. 快速回滚配置到稳定的版本
2. 快速找到是哪个版本引入的问题

### 使用 git 做为 neovim 的配置管理

这个其实很简单，你只需要把你的配置文件放到一个 git 仓库中.

你可以把你最稳定的分枝作为master， 然后你平时修修改改都在 dev 分枝上，当你想要一个功能，就可以在 dev 分枝上修改，然后自己使用一段时间，当功能稳定就将它合并到 master 中。

倘若 master 分枝的稳定版本出现来问题，我推荐一个 git 的神器命令 git-bisect, 你可以通过设置一个行为错误版本，和一个历史的行为正确的版本，这个命令会采用二分法的方式帮助你找到是哪个版本引入来这个问题。

### Troubleshooting

主要有几个命令吧:

`checkhealth` 会检查你的 neovim 的健康状况，比如说你的 neovim 是否支持 lua，是否支持 python, 插件依赖以及是否成功安装等等。
`nvim --startuptime` 会记录你的 neovim 启动的时间，你可以通过这个来找到是哪个插件导致了你的 neovim 启动变慢。 你也可以通过 Startuptime 这个插件来查看你的 neovim 启动时间。
`verbose <map type> <key>` 会显示你的按键映射的详细信息，比如说你的按键映射是否成功，是否有冲突等等。
`lua =vim.inspect(var)` 会打印你需要的变量的信息。

## 不需要突然地转换， 可以使用 ideavim 然后慢慢切换

如果你不是很熟悉 (neo)vim 的话，我建议你可以先尝试运行 vimtutor 这个命令，来学习一下 vim 的基本操作。
然后你可以在 jetbrains 使用 ideavim 来使用 vim 的快捷键，这样你就可以慢慢的切换到 neovim 中来。
纯 vim 开发其实不是一蹴而就的，需要一段时间的适应，但是我相信你会爱上它的。

## 不要无脑去直接使用 他人的配置

另外 neovim 其实有很多衍生的发行版本，我的建议是如果你不是很熟悉 neovim 的话，不要直接使用他人的配置，因为你可能会遇到很多问题，但是这些问题你不一定能自己解决，所以如果要使用就尽量从别人的 Minimal 模版中去建立自己的配置吧


## 有趣的事
* 使用 firenvim 作为浏览器的编辑器来刷 leetcode [twitter](https://twitter.com/GIA917229015/status/1573365264439480321)
* 使用 grammarly 作为 英语的language server 来检查你的语法错误

## END

你的 PDE 只是最适合你的环境, 本文章不提供作者的配置, 适合我的不一定适合你.

## 参考
* [PDE: A different take on editing code](https://www.youtube.com/watch?v=QMVIJhC9Veg&t=836s&ab_channel=TJDeVries)
* [nvim-lua-guide](https://github.com/nanotee/nvim-lua-guide)
* [jdhao](https://jdhao.github.io/)
