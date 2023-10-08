---
title: "Golang: How to Handle Growing Interfaces"
date: 2022-02-13T20:23:51+08:00
author: "xiantang"
# lastmod: 
tags: ["Golang","Refactor"]
categories: ["Golang"]
images:
  - ./post/how_to_fix_big_interface.png
description:
draft: false
---


<!-- 
* Always start with a sentence to synchronize the background and context
* Comment-style writing quotes some of the words of the big cows
* More interesting jump links
* Recommend some interesting links at the end of the article
* Write the outline first, then write the content -->

> The bigger the interface, the weaker the abstraction. [Go Proverbs](https://www.youtube.com/watch?v=PAAkCSZUG1c&t=317s)

Let's start with the conclusion. If your Golang interface has too many functions that make it difficult for you to expand horizontally, then split it into multiple interfaces according to its responsibilities, and then use embed to **combine** them.

## Problem Encountered

Recently, when refactoring a component that manages configurations, we have an interface and more than 5 structs implement this interface. We encountered some problems, that is, the problem of **interface bloating**. When you first abstract an interface, it may only have 1 - 2 functions, which is very beautiful, and you feel very comfortable when you expand horizontally.
But many times, the reality is different from what you imagine. Because each implementation may also have its own different methods that it wants to expose, at this time you will expose these functions, and each implementation will implement this function in order to satisfy the interface, which will lead to interface bloating.

## An Example

At first, I had an interface called `ConfigManager`, which had two functions, one was `HandleResync`, and the other was `HandleWatch`.

```Go
type ConfigManager interface {
 HandleResync()
 HandleWatch()
}
```

`HandleResync` and `HandleWatch` are both for pulling data from etcd. After pulling the data, we will write the data to disk, and also store a copy of the latest data in memory.

At the same time, this interface has two implementations, one is `EtcdConfigManager`, and the other is `FileConfigManager`. The names here are quite casual, mainly to express multiple implementations of an interface.

```Go
type EtcdConfigManager struct {
 config *Config
}

type FileConfigManager struct {
 config *Config
}

```

However, as the business continues to grow, we need to expose two more interfaces for `EtcdConfigManager` to perform actions such as reporting on in-memory replicas. These are `GetConfig` and `SetConfig`.

But for `FileConfigManager`, this implementation class actually does not need to expose the internal config.

At this time, many students will directly add two functions to the `ConfigManager` interface, and `FileConfigManager` will become the following look:

```Go
type ConfigManager interface {
  HandleResync()
  HandleWatch()
  GetConfig() *Config
  SetConfig(*Config)
}

// impl for `ConfigManager`
type FileConfigManager struct {
   config *Config
}
...
func (f *FileConfigManager) GetConfig() *Config {
 // painc here
 panic("implement me")
}

func (f *FileConfigManager) SetConfig(c *Config) {
 // painc here
 panic("implement me")
}
```

Although the problem has been successfully solved, it will cause some problems:

* If there is a new configuration to be managed, it will need to satisfy 4 functions to implement this interface.
* If there are already 10 implementation classes that have implemented `ConfigManager`, if you want to add a new function to the `ConfigManager` interface, then these 10 implementation classes need to be updated, which will be a lot of work.
* Exposing too much internal information to the outside world, if it involves authority issues, it will cause problems such as asset loss.

In fact, in the company's codebase, there are already interfaces with 10+ functions, and horizontal expansion is simply a nightmare.

## How I solved it

Because I was fed up with the problem of interface inflation, I really racked my brains. Although the author of Golang always says to keep the interface small, he actually didn't tell us how to prevent interface inflation. Finally, I found a solution in the io package of Golang.

In the interfaces defined from [io.go#83](https://github.com/golang/go/blob/master/src/io/io.go#L83) to [io.go#172](https://github.com/golang/go/blob/master/src/io/io.go#L172).

### Split the interface

We found that he split a bunch of small interfaces with only 1 - 2 functions according to their functions.
like：

```Go
type Reader interface {
 Read(p []byte) (n int, err error)
}
type Writer interface {
 Write(p []byte) (n int, err error)
}
type Closer interface {
 Close() error
}
type Seeker interface {
 Seek(offset int64, whence int) (int64, error)
}
```

### Concatenate the interface

Use the incremental concatenation method to concatenate these interfaces:

```go
type Writer interface {
 Write(p []byte) (n int, err error)
}
type WriteSeeker interface {
 Writer
 Seeker
}
type ReadWriteSeeker interface {
 Reader
 Writer
 Seeker
}
```

### Convert the interface

At the same time, when passing parameters, only pass the smaller interface, and then convert to other interfaces as needed.

```Golang
func WriteString(w Writer, s string) (n int, err error) {
 if sw, ok := w.(StringWriter); ok {
  return sw.WriteString(s)
 }
 return w.Write([]byte(s))
}
```

### Benefits

The benefits of this are

* *Expose as little information as possible to the user*: For all implementation classes, we only need to implement the necessary functions, without having to satisfy all the functions of the above interface.
* *Stronger abstraction capability*: Because your interface only has 1 - 2 functions, horizontal expansion is simpler, which is why the io.Writer interface can easily write 20+ implementation classes.

## Refactoring the above code

For the above code, we can refactor it:

We can refactor the `ConfigManager` with 4 interfaces into two small interfaces, and then combine them:

```golang
/*
type ConfigManager interface {
  HandleResync()
  HandleWatch()
  GetConfig() *Config
  SetConfig(*Config)
}
*/

type EventHandler interface {
   HandleResync()
   HandleWatch()
}

type DataHolder interface {
    GetConfig() *Config
    SetConfig(*Config)
}

type DataEventHandler struct {
     DataHolder
     EventHandler
}
```

In this way, `FileConfigManager` can only implement the `EventHandler` interface, reducing the exposed information, and can not implement those functions that do not want to be exposed.

The main logic will also be simpler:

```golang
func mainLoop(handler EventHandler) {
    // just example

    // resync
    handler.HandleResync()

    // watch
    handler.HandleWatch()

    // ...
    // report data
    if h,ok := handler.(DataEventHandler); ok {
     report(h.GetConfig())
    }
}

```

## Conclusion

In summary, there are the following points of my best practice:

* Ensure that the interface is small enough with 1 - 2 functions, so that the interface can be expanded more simply, and the name of the interface can use a single word, eg: `Reader`, `Writer`, `Closer`, `Seeker`.

* Use the method of interface combination to combine large interfaces.

* Use the method of interface conversion in the main process to convert small interfaces into large interfaces.
* [Go: How to deal with the constantly expanding interface](https://jishuin.proginn.com/p/763bfbd7078f)
* [Using Interface Composition in Go As Guardrails](https://rauljordan.com/2021/06/10/using-interface-composition-in-go-as-guardrails.html)
* [Go Interfaces with more than one method - Acceptable or unacceptable?](https://stackoverflow.com/questions/45395982/go-interfaces-with-more-than-one-method-acceptable-or-unacceptable)

## Recommended Section

Finally, I would like to share with you some good articles that I have been reading recently. I thought about sending them in a weekly newsletter, but since my reading is quite scattered, I decided to put them at the end of each blog post. I hope you find them useful!

* [How to Write a Git Commit Message](https://cbea.ms/git-commit/) Recommendation: This method of writing git commit messages is very useful for people like me who only know how to write "fix xxxx issue" every day.

* [Career Advice Nobody Gave Me: Never Ignore a Recruiter](https://index.medium.com/career-advice-nobody-gave-me-never-ignore-a-recruiter-4474eac9556) Programmers don't like headhunters, but this article tells us that headhunters are actually very important.

* [A Self-Help Guide for Programmers Facing Panic and Boredom](https://vikingz.me/save-yourself/) WFH really increases anxiety. This article gave me some inspiration, and I might write an article on overcoming anxiety in the future.

* [《Communication of Love》](https://book.douban.com/subject/30248303/) taught me how to communicate and prevent defensive listening.
