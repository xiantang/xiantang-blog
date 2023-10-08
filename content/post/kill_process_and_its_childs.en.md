---
title: "How to kill a process and its descendants in Unix?"
date: 2022-01-24T21:49:48+08:00
author: "xiantang"
# lastmod: 
tags: ["Chinese", "Golang"]
categories: ["Golang"]
images:
  - ./post/kill_process_and_its_childs.png
description:
draft: false
---


<!-- 
* Always start with a sentence to synchronize the background and context
* Comment-style writing quotes some big cows
* More interesting jump links
* Recommend some interesting links at the end of the article
* Write the outline first, then the content -->

> Recently, I was maintaining an open source project called [air](https://github.com/cosmtrek/air) on the weekend. It is a hot loading code tool for Golang, which will monitor local file changes and then automatically reload.

## Problem encountered

Recently, I encountered a particularly interesting problem, that is, when using the `kill -9 pid` command to kill the process, although it will kill its child process, its grandchild process will still survive.

## Background

In short, our hot loading component will run commands, and then will monitor file changes, once the file changes, it will kill the previous process, then recompile the code, and then execute the running command.

But I encountered a user who raised such a problem: <https://github.com/cosmtrek/air/issues/216#issuecomment-982348931> When executing the command, use `dlv exec --accept-multiclient --log --headless --continue --listen :2345 --api-version 2 ./tmp/main` to run the code and start debugging, our component will not completely kill the process, but will continue to survive. This causes the corresponding port to be occupied the next time it comes up.

## Troubleshooting

Through `ps -efj | grep "tmp/main"` you can clearly see that actually running this command will start three processes

```s
1594910868 75277 74711   0 10:09PM ttys005    0:00.14 dlv exec --accep xt       75277      0    1 S    s005
1594910868 75280 75277   0 10:09PM ttys005    0:00.02 /Library/Develop xt       75280      0    1 S+   s005
1594910868 75281 75280   0 10:09PM ttys005    0:00.01 ./tmp/main       xt       75280      0    1 SX+  s005
```

And it's very clear to see the grandparent-child relationship of the processes:

75277 is the parent process

75280 is the child process

75281 is the grandchild process

If you just use `kill -9 pid` to kill the process, its child process will also be killed, but the grandchild process will still survive.

```s
> kill -9 75277
> ps -ef | grep "tmp/main"
1594910868 75281     1   0 10:09PM ttys005    0:00.01 ./tmp/main
```

You can see that only the 75281 process is left, and the parent process of this process has now become 1, an orphan process. It's really an orphan.

If this process continues to occupy the port, it will prevent the command from being executed normally the next time.

## Solution

After consulting various materials, I found a good solution: use the pgid parameter to allow the processes in the process group to share a process group number.

```s
  PID  PPID  PGID   UID   C STIME   TTY             TIME CMD              
75837 74711 75837 1594910868   0 10:22PM ttys005    0:00.23 dlv exec --accep 
75840 75837 75840 1594910868   0 10:22PM ttys005    0:00.02 /Library/Develop 
75841 75840 75840 1594910868   0 10:22PM ttys005    0:00.01 ./tmp/main       
```

You can see that the third column corresponds to the pgid. Although the pgid we start with the command is different, we can use Golang to set the process group number, so that we can share the process group number.

At the same time, when killing the process, you also need to use this pgid parameter, so that you can kill the corresponding process group. You can refer to `man kill`

> Negative PID values may be used to choose whole process groups; see the PGID column in ps command output.

That is, for pid, it represents PGID, which is the entire process group. When killing, it will kill all processes in the process group.

Although it is impossible to share processes in the above command, for this bug, we can use `Setpgid` to enable PGID, so that the started process can share the process group number. At the same time, use `syscall.Kill(-pgid, 15)` to kill the process group.

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

## Conclusion

Add relevant unit tests in the unit test to ensure that the behavior of `kill` all child processes will not be lost due to iteration. <https://github.com/cosmtrek/air/commit/1c27effe33a180f3fbbcee8f2d9ea7122d89a50b#diff-6266cec6be43e607de84d431f656ea78fac62405058d84312d9c12f3f52c7462R146>

### Reference Materials

* <https://groups.google.com/g/golang-nuts/c/XoQ3RhFBJl8>
* <https://stackoverflow.com/questions/392022/whats-the-best-way-to-send-a-signal-to-all-members-of-a-process-group>
* <https://forum.golangbridge.org/t/killing-child-process-on-timeout-in-go-code/995/2>

## Recommended Section

Finally, I would like to share with you some good articles that I have been reading recently. I thought about sending them in a weekly newsletter, but because I read them sporadically, I decided to put them at the end of each blog post. I hope you find them useful!

* [The Pomodoro Technique for Intermittent High Efficiency](https://book.douban.com/subject/35119866/) After reading an article in a news letter, I discovered a crucial [trick](https://happyxiao.com/pomodoro/): If you set a Pomodoro timer for a task, but finish early, say you're taking notes for a chapter in a book, but you finish early - you shouldn't immediately move on to the next task, or end the Pomodoro timer early.

* [Writing infinite alerts in Japan will get you arrested](https://blog.kalan.dev/2022-01-23-infinite-alert-loop/)

* Useful commands for checking dependencies between two Golang modules
  * go mod graph
  * `go mod why -m  "module"`
  
* [Nginx founder leaves F5](https://www.nginx.com/blog/do-svidaniya-igor-thank-you-for-nginx/)
