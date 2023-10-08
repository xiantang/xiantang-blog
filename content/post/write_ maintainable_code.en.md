---
title: "Some Practices and Thoughts on Writing Maintainable Code"
date: 2022-04-10T23:08:16+08:00
author: "xiantang"
# lastmod: 
tags: ["code"]
# categories: []
# images:
#   - ./post/golang/cover.png
description:
draft: false
---

# Some Practices and Thoughts on Writing Maintainable Code

Recently, I have been modifying a piece of historical code that has a distinct style and has been handled by many hands. I found that there are many mistakes in the design of the code. This makes it very difficult for me to modify the code and add new features. This article is written with personal emotions, so there may be some subjectivity.

Below, I list a few coding behaviors that I think greatly affect maintainability.

## Repeating the same logic

Long, identical logic, written twice. Many times, some developers encounter a piece of historical code with poor performance, but lack the time to optimize this code, so we will rewrite a set of code with the same behavior and open an API interface for use. Although this does indeed complete the existing task, it is actually very risky.

If a new colleague needs to modify the existing API behavior, he will fall into a big pit, because two sets of logic are running online at the same time and have the same behavior. It is very likely that this new colleague may only change one set of logic and ignore the other set. This situation is really easy to exist, because newcomers often lack information. In the case of insufficient QA, it will introduce difficult-to-troubleshoot BUGs.

## Don't just add if else special logic

Many times, we encounter some requirements, a simple look actually does not need to modify, just need to add a sentence of if else such special logic in the main process or abstraction.
This simple judgment logic is likely to give you a punch in the near future, such as two or three months later.
Before considering adding if else, think about whether it is convenient for you to modify it later? Can it be written in the configuration file and modified by the configuration center?
If you really need to add it, you need to add comments to this code. You need to determine the behavior of your own code, not pile up a bunch of logic, and when others ask about the behavior, say it might do this? Might do that? 
Programming by coincidence will only bring more and more problems.

## Delayed abstraction

Programmers are a very interesting group, especially fond of the matter of `abstraction`, including me. I have seen good abstractions and bad abstractions in various repositories. The worse abstraction is often the kind that exposes 10+ functions in an `interface`, and each function's real implementation is only two or three lines, we generally call it `wide interface`. Its disadvantage is that when you expand horizontally, you need to implement 10+ functions, which is very painful, and the flexibility is very poor. At the same time, each implemented function is likely to be an empty implementation, with no actual execution code inside.

My suggestions are:

1. Start by writing some implementation classes, initially using simple switch statements and other behavior controls for calls, then gradually abstract the upper-level interfaces based on the commonality of the implementation classes. If you are using `Go`, you can refer to my previous thoughts on Golang abstraction. [Golang: How to handle the ever-expanding interface](https://vim0.com/post/how_to_fix_big_interface/)
2. Greatly reduce the number of functions in the interface, with a maximum of 4 functions per interface, which makes it easier to implement. Break down the large interface into different interfaces according to the `single responsibility principle`, and then combine them into different large interfaces. You can refer to the implementation of Golang at https://cs.opensource.google/go/go/+/refs/tags/go1.18:src/io/io.go;l=127.

## Write less flashy code

A line of code is written once, but it will be read hundreds of times, so simplicity is important when writing. Showy code/overuse of design patterns makes the code difficult to maintain and adds complexity to the system.

## Group the code together

I often find some code where the entire function has 500+ lines, with no comments, and 70% of the entire function is done in a for loop.
My suggestion is that if you break down what this function needs to do into smaller tasks before writing the code, and there are comments in front of each task, the readability of the code will be much better.


# Conclusion

The rant is over, I hope I can think more when writing code and write code that is easy to modify.
