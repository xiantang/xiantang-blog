---
title: "How to learn Scala"
date: 2020-01-15T16:33:34+08:00
tags: ["scala"]
categories: ["English","scala"]
draft: false
---

## Background:

When I first came to a company with Scala as its technology stack, I spent a long time setting up the environment. After finally getting the project up and running, I found the code inside to be very strange. There were no loops, and data operations were a function nested within another function. This was very puzzling. So, driven by business needs and curiosity, I began to learn about Scala.

## Goals:

1. Proficiently use asynchronous operations Future transformations (synchronous thinking to asynchronous)
2. Familiarize with the Play framework and be able to proficiently solve problems by looking up documentation
3. Proficiently use higher-order functions like map, flatMap, etc.

### Stage 1: Able to write Scala

This stage is relatively easy to reach. First, you need to read the first few chapters of "[Scala Programming](https://www.douban.com/link2/?url=https%3A%2F%2Fbook.douban.com%2Fsubject%2F5377415%2F&query=scala+programming&cat_id=1001&type=search&pos=1)" or "[Twitter Scala Classroom](https://twitter.github.io/scala_school/zh_cn/index.html)" to understand the basic syntax of Scala. However, there will still be many pitfalls at this stage, and you can only barely write code under the guidance and error prompts of IDEA.

### Stage 2: Understand what functional programming is

After you have been writing Scala for about half a month and are still curious about what functional programming is, you can start learning about functional programming. My route was to first take the introductory course "[Programming Languages](https://www.coursera.org/learn/programming-languages/home/welcome)", which mainly taught some basic knowledge about functional programming, including but not limited to closures, higher-order functions, tail recursion, and algebraic types. Although the language is not Scala, this course laid a solid foundation for my subsequent functional programming. If you complete the assignments seriously in this course, the road ahead will be much smoother.

### Stage 3: Further understanding

By this time, you must have heard of a very famous book, "Scala Functional Programming". It is very likely that you read it before you went through the previous stages, but found the content to be very abstract and gave up. Now you can boldly read it, and you can painlessly read up to Chapter 6.

Below, you will be confused by more abstract concepts such as Monad Factor.

### Stage 4: Continuous Learning Basics

The above blockage is actually due to the lack of solid basic knowledge, so further learning is still needed. Here I recommend the course [Functional Programming Principles in Scala](https://www.coursera.org/learn/progfun1/home/welcome) by the author of the Scala language. Because it is not free, you need to pay or use a scholarship (salted fish) to study for free. Although this course is not as good as the above programming-languages course, the more difficult exercises can still improve the level of FP.

### Stage 5: Participate in the Community

At this time, you can continue to read the book "Scala Functional Programming". Because you have finished the two all-English courses above, you will no longer be afraid of English and can participate in the community. Here are a few recommended good communities that have helped me in the past https://gitter.im/scala/scala.   https://gitter.im/akka/akka , if you are interested in open source, you can fix bugs for akka or Play.

Finally, I recommend some websites that have helped me

[coursera.org](http://coursera.org/)  Online course platform

https://www.playframework.com/ play official website

https://stackoverflow.com/ scala module Basically 99% of scala problems can be found on it, provided that you can search

https://github.com/ Find the wheel
