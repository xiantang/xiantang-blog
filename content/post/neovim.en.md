---
title: "Using neovim as a PDE (Personalized Development Environment)"
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


<!-- * Always start with a sentence, synchronizing background and context -->
<!-- * What you can learn from this article -->
<!-- * Comment-style writing quotes some big shots -->
<!-- * More interesting jump links -->
<!-- * Recommend some interesting links at the end of the article -->
<!-- * Write the outline first, then the content -- -->

This article will not tell you how to configure neovim step by step, but will tell you some "Tao" about PDE, not the specific practice of "Art".

## Introduction to neovim and PDE

Seeing TJ's YouTube introduced the use of neovim as a PDE, it was interesting, so I tried it myself, it felt good, so I recorded it.

### What is neovim

Neovim is a branch of vim, vim is a text editor, neovim is a branch of vim, its goal is to provide a better vim, not a substitute for vim.

What's the difference between neovim and vim? 
The difference is that neovim has refactored vim's code, supports lua scripts as configuration language on the basis of compatible vimscipt. At the same time, neovim's community on Github is more active than vim's. Neovim has a more useful lsp server, you can understand neovim is a superset of vim.


### What is PDE

PDE is a personalized development environment, which means that on the basis of meeting basic development needs, users can script and customize their development environment, thereby improving user development experience and efficiency.


As you continue to solve the pain points in your development environment, your development efficiency will get higher and higher, and your development experience will get better and better, this is the charm of PDE.

You can also continue to learn new things from it, in this process, you will also get a sense of accomplishment.


## Basic needs to be met


Define the basic needs that your PDE needs to meet, such as:

* Highlighting
* lsp
  * Basic refactoring rename
  * Quick jump
* lint
* Code suggestion
* Code snippet
* Debugging
* Quickly find recent files

Because only by satisfying these basic needs can you ensure that you will not return to your old editor. Keep finding your own pain points on top of this, and then solve them, you will get faster and faster and master this tool more and more.

## Personalized needs

Sometimes I always have some interesting needs, let me just give an example:

For example, I often modify multiple projects in vim at the same time, but NERDTreeFind in nerdtree will only find from the current tree, and the root directory of the tree is always wrong. My requirement is to find this file in the bookmarks of nerdtree, and the root directory is the first matched bookmark.

![show off](https://user-images.githubusercontent.com/34479567/204140677-0c11c2c8-cca7-44d2-8971-12632e3f0874.gif)

You can refer to my implementation:

https://github.com/xiantang/nvim-conf/blob/dev/lua/nerdtree.lua

Basically all the functions you want can be achieved by modifying lua, or by using nvim series plugins.

1. For example, quickly call up a terminal or a note txt
2. Add some custom snippets
3. And so on...

## Better configuration management

In fact, when everyone uses neovim to make their own PDE, they will find that you can easily mess up your neovim, because there are many plugins in your configuration, and these plugins are often incompatible. So the following two points are crucial:

1. Quickly roll back the configuration to a stable version
2. Quickly find out which version introduced the problem

### Use git as the configuration management of neovim

This is actually very simple, you just need to put your configuration file in a git repository.

You can use your most stable branch as the master, and then you usually modify it on the dev branch. When you want a function, you can modify it on the dev branch, and then use it for a while. When the function is stable, merge it into the master.

If the stable version of the master branch has a problem, I recommend a god command of git, git-bisect. You can set a behavior error version and a historical behavior correct version. This command will use a binary method to help you find out which version introduced this problem.

### Troubleshooting

There are several main commands:

`checkhealth` checks the health of your neovim, such as whether your neovim supports lua, whether it supports python, whether the plugin dependencies are successfully installed, etc.
`nvim --startuptime` records the startup time of your neovim. You can use this to find out which plugin is slowing down your neovim startup. You can also use the Startuptime plugin to view your neovim startup time.
`verbose <map type> <key>` displays detailed information about your key mapping, such as whether your key mapping is successful, whether there are conflicts, etc.
`lua =vim.inspect(var)` prints the information of the variable you need.

## No need to switch suddenly, you can use ideavim and then switch slowly

If you are not very familiar with (neo)vim, I suggest you try running the vimtutor command first to learn the basic operations of vim.
Then you can use vim shortcuts in jetbrains using ideavim, so you can slowly switch to neovim.
Pure vim development is not achieved overnight, it takes some time to adapt, but I believe you will love it.

## Don't blindly use other people's configurations directly

In addition, neovim actually has many derivative distributions. My suggestion is that if you are not very familiar with neovim, do not directly use other people's configurations, because you may encounter many problems, but you may not be able to solve these problems yourself, so if you want to use it, try to build your own configuration from other people's Minimal templates.


## Interesting things
* Use firenvim as a browser editor to brush leetcode [twitter](https://twitter.com/GIA917229015/status/1573365264439480321)
* Use grammarly as an English language server to check your grammar errors

## END

Your PDE is just the most suitable for your environment, this article does not provide the author's configuration, what suits me may not suit you.

## References
* [PDE: A different take on editing code](https://www.youtube.com/watch?v=QMVIJhC9Veg&t=836s&ab_channel=TJDeVries)
* [nvim-lua-guide](https://github.com/nanotee/nvim-lua-guide)
* [jdhao](https://jdhao.github.io/)

Sure, please provide the Markdown content you want to translate.
