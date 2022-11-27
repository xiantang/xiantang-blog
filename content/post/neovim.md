---
title: "使用 neovim 作为 PDE(个性化开发环境)"
date: 2022-10-29T20:45:20+08:00
author: "xiantang"
# lastmod: 
# tags: []
# categories: []
# images:
#   - ./post/golang/cover.png
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


修改 lua 来达成 
* toggle 
* 智能化 locate 文件

## 更好的配置管理

### 使用 git 做为 neovim 的配置管理
* 平移配置

### Troubleshooting


## lua 作为 neovim 的配置语言

lua 是什么

## 不需要突然地转换， 可以使用 ideavim 然后慢慢切换

## 不要无脑去直接使用 他人的配置

你的 PDE 只是最适合你的环境

## 防止配置随着插件变多而导致的卡顿
## 有趣的事
* 使用 firenvim 作为浏览器的编辑器来刷 leetcode
* 使用 grammarly 作为 英语的language server 来检查你的语法错误

