---
title: "Unix 如何杀死一个进程和它的子孙进程?"
date: 2022-01-24T21:49:48+08:00
author: "xiantang"
# lastmod: 
tags: ["中文", "Golang"]
categories: ["Golang"]
images:
  - ./post/kill_process_and_its_childs.png
description:
draft: false
---


<!-- 
* 总是会先写一句话，同步背景和上下文
* 评论式写作引用一些大牛说的话
* 多一些有趣的跳转链接
* 在文章末尾推荐一些有趣的链接
* 先写提纲，再写内容 -->

> 最近周末在维护一个开源项目，叫做 [air](https://github.com/cosmtrek/air)。它是一个 Golang 的热加载代码的工具，会监听本地的文件变化，然后自动重新加载。

## 遇到的问题

最近遇到一个特别有意思的问题，就是使用 `kill -9 pid` 命令杀死进程的时候虽然会杀死它的子进程，但是它的孙子进程还是会继续存活。

## 背景

简而言之，就是我们的热加载组件会运行命令，然后会监听文件变化，一旦文件变化就会 kill 掉之前进程，然后重新编译代码，再执行运行的命令。

但是遇到一个用户提了这样一个问题：<https://github.com/cosmtrek/air/issues/216#issuecomment-982348931> 在执行命令的时候使用 `dlv exec --accept-multiclient --log --headless --continue --listen :2345 --api-version 2 ./tmp/main` 来运行代码与开启调试，我们的组件不会彻底的将进程杀死，而是会继续存活。导致下次一次起来的时候对应的端口会被占用。

## 排查问题

通过 `ps -efj | grep "tmp/main"` 能很清楚的看到实际上运行这条命令会起来三个进程

```s
1594910868 75277 74711   0 10:09PM ttys005    0:00.14 dlv exec --accep xt       75277      0    1 S    s005
1594910868 75280 75277   0 10:09PM ttys005    0:00.02 /Library/Develop xt       75280      0    1 S+   s005
1594910868 75281 75280   0 10:09PM ttys005    0:00.01 ./tmp/main       xt       75280      0    1 SX+  s005
```

而且是很清晰的能看出来，进程的祖孙关系：

75277 是父进程

75280 是子进程

75281 是孙进程

如果你只是采用 `kill -9 pid` 来杀死进程，那么它的子进程也会被杀死，但是孙子进程还是会继续存活。

```s
> kill -9 75277
> ps -ef | grep "tmp/main"
1594910868 75281     1   0 10:09PM ttys005    0:00.01 ./tmp/main
```

可以发现只剩下 75281 这个进程了，而且这个进程的父进程现在变成了 1，孤儿进程了。属实是孤儿了。

如果这个进程还继续占用着端口，会造成下次执行命令的时候无法正常热加载。

## 解决方案

查阅了各种资料之后，找到了一个很好的解决方案：使用 pgid 参数来让进程组的进程共享一个进程组号。

```s
  PID  PPID  PGID   UID   C STIME   TTY             TIME CMD              
75837 74711 75837 1594910868   0 10:22PM ttys005    0:00.23 dlv exec --accep 
75840 75837 75840 1594910868   0 10:22PM ttys005    0:00.02 /Library/Develop 
75841 75840 75840 1594910868   0 10:22PM ttys005    0:00.01 ./tmp/main       
```

可以看到第三列就是对应的 pgid，虽然我们使用命令启动的 pgid 不同，但是我们可以使用 Golang 来设置进程组号，这样就可以共享进程组号了。

同时在 kill 进程的时候，也要使用这个 pgid 参数，这样就可以杀死对应的进程组了。可以参考 `man kill`

> Negative PID values may be used to choose whole process groups；see the PGID column in ps command output。

就是对于 pid 的代表的是 PGID 也就是整个进程组，kill 的时候会将整个进程组中的进程杀死。

虽然在上面的命令中是没办法共享进程的，但是对于这个 bug 来说，我们可以使用 `Setpgid` 来开启 PGID，这样启动的进程就可以共享进程组号了。同时使用 `syscall.Kill(-pgid, 15)` 来杀死进程组。

```go
cmd := exec.Command( some_command )
cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
cmd.Start()

pgid, err := syscall.Getpgid(cmd.Process.Pid)
if err == nil {
syscall.Kill(-pgid, 15)  // note the minus sign
}

cmd.Wait()
```

## 总结

在单测中添加相关的单测，保证 `kill` 所有子进程这个行为不会因为迭代而丢失。<https://github.com/cosmtrek/air/commit/1c27effe33a180f3fbbcee8f2d9ea7122d89a50b#diff-6266cec6be43e607de84d431f656ea78fac62405058d84312d9c12f3f52c7462R146>

### 参考资料

* <https://groups.google.com/g/golang-nuts/c/XoQ3RhFBJl8>
* <https://stackoverflow.com/questions/392022/whats-the-best-way-to-send-a-signal-to-all-members-of-a-process-group>
* <https://forum.golangbridge.org/t/killing-child-process-on-timeout-in-go-code/995/2>

## 推荐环节

最后最后和大家分享一些最近在看的好文，想过用周刊的方式发送但是因为看的比较零散，就放在每篇博文的最后，希望大家能够收获！

* [間歇高效率的番茄工作法](https://book.douban.com/subject/35119866/)看了一个 news letter 的文章，发现了一个至关重要的[技巧](https://happyxiao.com/pomodoro/)：如果你为一个任务设置了一个番茄钟，但是提早完成了，比方说你为一本书的某个章节记笔记，但你提早完成了 - 你不应该立即进入到下一个任务，或者提早结束这个番茄钟。

* [在日本写无限 alert 会被抓](https://blog.kalan.dev/2022-01-23-infinite-alert-loop/)

* Golang 检查两个模块依赖好用命令
  * go mod graph
  * `go mod why -m  "module"`
  
* [Nginx 创始人离开 F5](https://www.nginx.com/blog/do-svidaniya-igor-thank-you-for-nginx/)
