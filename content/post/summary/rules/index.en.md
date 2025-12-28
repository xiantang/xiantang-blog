---
title: "Summary of Commonly Used Principles in Computing"
date: 2021-11-10
tags: ["summary"]
categories: ["English","Principles"]
draft: false


---

## Commonly Used Principles in Computing

When writing code, we often have some insights and experiences. These experiences have long been summarized into principles by the predecessors. In the past year, I have been collecting various principles and constantly applying and practicing them.

### KISS Principle

The **KISS Principle** is an acronym for **K**eep **I**t **S**imple, **S**tupid.

The KISS principle refers to the principle that **simplicity should be emphasized** in design. Summarizing the experience of engineering professionals in the design process, most system designs should remain simple and pure, without incorporating unnecessary complexity, so that the system can operate optimally.

The correct approach should be for developers to break down a problem into understandable small pieces after encountering it, and then enter the coding phase.

- Advantages:
  - You will be able to solve complex problems with just a few lines of code.
  - You will be able to produce high-quality code.
  - When new requirements come, your code will be more flexible.

- How to use:
  - You're not a genius, your code is stupid simple, so you don't need to be a genius.
  - Break down problems. Break tasks down into 4 - 12 hour subtasks.
  - Solve each subtask with one or very few classes. **Keep classes small** and don't put too many use cases in them.
  - Keep methods short enough. 30 - 40 lines.
  - Try to keep things simple in any scenario.

### DRY Principle

Don't repeat yourself.

This principle is actually particularly commonly used in work, for example, if you often write repetitive code, you can abstract it into a function.

But I think the best practice is: if something is done 3 times, then abstract it into a function or do abstraction, because premature abstraction can lead to lack of universality and is not conducive to code maintenance.

### YAGNI Principle

You aren't gonna need it, YAGNI means "you don't need it": don't do extra things before it's necessary.

This principle mainly tells us not to think about a problem too early, to reduce the cost of implementation.
Although it contradicts the former, we can try to abstract it by doing it 3 times as I mentioned above, which will be a better compromise.

### Single Responsibility Principle

The Single Responsibility Principle (SRP) simply means that a class should only be responsible for one duty, not multiple duties. In program design, the single responsibility principle is a very important principle because it can help us better organize code, better manage code, and better solve problems.

Let each class do one thing, rather than letting each class do everything, which will make the maintenance and expansion of the code more convenient.

### Interface-oriented programming principle

The Interface Segregation Principle, simply put, is to use as many interfaces as possible, rather than using many classes.

The advantage of this is: the program is divided into different modules, what is exposed to the outside is the upper-level interface, not the lower-level class. In this way, when the implementation is modified, the upper-level interface does not need to be modified, only the lower-level class needs to be modified.
