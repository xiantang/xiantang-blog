---
title: "Why do I use bidirectional links for note-taking?"
date: 2022-02-27T23:15:45+08:00
author: "xiantang"
# lastmod: 
tags: ["Bidirectional Links"]
categories: ["Notes"]
# images:
#   - ./post/golang/cover.png
description:
draft: false
---


<!-- 
* Always start with a sentence to synchronize the background and context
* Comment-style writing quotes some words from experts
* More interesting jump links
* Recommend some interesting links at the end of the article
* Write the outline first, then the content -->

> The value of a person lies in finding connections between memorized information.

I previously recommended bidirectional link software to my friends for rote memorization, and many people asked me "Why use bidirectional links? What are the benefits?". 
I will write a short article here to answer these questions.

I have tried many note-taking software before, such as Notion, Evernote, and even Typora managed directly with git. Most of the time, I didn't have the motivation to take notes.
The main reasons are:

* There is no use when looking at the notes for the second time, it just looks like a mess. As shown below:
![Previous notes](2022-02-27-23-32-09.png)
* When taking notes, I don't know where to write? This folder or that folder?

* There is no connection between the notes, no relevance, and the reusability of the knowledge points is very low. Writing is just for the sake of writing.

I found bidirectional links, which is a new way of note-taking, and it allows us to directly find the original knowledge points in the notes.

## What are bidirectional links?

Bidirectional links refer to the reference relationship between two notes. For example: Note A refers to Note B, and Note B will automatically refer to Note A, then the two notes are interrelated, which is a bidirectional link, supporting bidirectional jumps.

## What are the benefits of bidirectional links?

I will list a few benefits of bidirectional link notes:

1. **Good reusability**, when you write down an entry, if the later notes can directly refer to this entry.

2. **No pressure to record**, because you know that constantly linking notes can help you in the future, you will be more motivated to record. At the same time, you don't need to think about where to write the notes, just write the related content directly into the entry, let them link to each other. Later, you can easily find the notes.

3. **Facilitates internalization**, when you plan to write an article, there may be many concepts. If you have accumulated these concepts in bidirectional link notes before, then you can directly refer to these concepts. At the same time, for this concept, you can know which notes refer to this concept. In this way, you can more completely find out the knowledge points you have summarized before, and output a complete summary article.

## Examples

### I want to learn a concept

Some time ago, I was learning a concept called `Golang Channel`, and I read related articles, such as: "Channel Axioms", "Golang Channels Tutorial", "Effective Go".

First, I would write the concept of Channel into the bidirectional link notes:

![](/image/2022-02-28-00-02-46.png)


### Making records

For each article, I would write an entry in the bidirectional link notes, this entry is the title of the article, and then write the notes of the article in the entry.
But this note is not simply copied up, but written in my own language, I need to chew it myself. For example, the above Channel's axioms:

![](../2022-02-28-00-21-46.png)


### Review

When you need to do output and review, you just need to open the Channel entry, and you can find all the notes that referenced Channel before.

![](../2022-02-28-00-22-14.png)

The benefits of this are obvious, when we output to make an outline, the notes of these reverse links will provide good help. Initially, there were few entries when recording, but after a period of time, we can write the entries more completely. At the same time, the cost will become very low after outputting an article.

## References

* [Channel Axioms](https://dave.cheney.net/2014/03/19/channel-axioms)
* [Bidirectional Link and Knowledge Star Map User Guide-Windows/Mac side](https://staging.yinxiang.com/hc/articles/knowledge/)
