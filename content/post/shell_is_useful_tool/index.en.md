---
title: "Shell is a good productivity tool"
date: 2022-09-12T14:34:53+08:00
author: "xiantang"
# lastmod: 
# tags: []
# categories: []
# images:
#   - ./post/golang/cover.png
description:
draft: false
---


<!-- 
* Always start with a sentence, synchronize the background and context
* What you can learn from this article
* Comment-style writing quotes some big names
* More interesting jump links
* Recommend some interesting links at the end of the article
* Write the outline first, then the content -->


> If a sequence of three commands is executed twice in a row, it is recommended that you write it as a Shell script -- blog.fleeto.us

Recently, I increasingly realize that shell can replace python as the second language for devops engineers.

Because daily work may be repetitive, many repetitive operations in work can be reduced by shell scripts to reduce mental burden.

Let me give you an example:

* Log in to the company's intranet through vpn
* Daily problem troubleshooting scripts

You can turn shell into a set of clear tools, combined through the pipe method, to complete your work.

You can manage these scripts through a repository, because the advantage of this is that these scripts can be easily maintained, and when you modify the script and encounter problems, you can easily roll back to the historical version.

Continuously maintaining and refactoring your own shell script library, you will find that your work efficiency will greatly improve.
