---
title: "Using the 80/20 Rule to Learn awk Effortlessly"
date: 2022-06-29T22:14:09+08:00
author: "xiantang"
lastmod:
tags: ["Chinese","Soft Skills","awk"]
categories: ["Chinese","awk"]
images:
  - ./post/awk.png
description:
draft: false
---

<!-- 
* Always start with a sentence to synchronize the background and context
* Comment-style writing quotes some big names
* More interesting jump links
* Recommend some interesting links at the end of the article
* Write the outline first, then the content -->

> The length only accounts for 20%, but the effectiveness reaches 80% - 80/20 Rule

# What can you learn from this article?

In this article, we will learn how to use the 80/20 rule to effortlessly learn the linux text processing command awk. After reading this article, you will learn a fast learning method,
and how to use awk to process text and stdout.

Recently, while learning awk, I found that there are really many details. It's impossible to grasp the most important part at the beginning, and I'm troubled by the complicated syntax, which is quite difficult to understand.
So I used the 80/20 rule I learned from "Soft Skills: The Software Developer's Life Manual" to practice the basic usage of awk, and found the effect to be very good.
This article will introduce how I used the 80/20 rule to learn awk.

## What is the 80/20 Rule?

At the beginning of the article, it was mentioned that "the length only accounts for 20%, but the effectiveness reaches 80%", which is called the "Pareto Principle". It points out that about 20% of the factors can affect 80% of the results.
This is also very applicable to learning technology. The most used 20% of technical knowledge points can complete 80% of technical work. That is to say, we actually only need to focus on the most common
cases for targeted learning, to prevent the truly important content from being buried in the details.

## How to Use the 80/20 Rule to Learn?

Since the 80/20 rule is so useful, how can it be practiced? "Soft Skills: The Software Developer's Life Manual" mainly summarizes 10 steps, that is, learning a new technology can be completed through the following ten steps:

- Step 1: How to start: What basic knowledge do I need to use it?
- Step 2: Scope of the subject: How big is the thing I'm learning? What should I do?
- Step 3: Need to understand basic user cases, and common problems, know which 20% to learn to satisfy 80% of application scenarios
- Step 4: Find resources
- Step 5: Define goals
- Step 6: Filter resources
- Step 7: Start learning, taste and stop
- Step 8: Hands-on operation, learn while playing
- Step 9: Master it fully, learn to use it
- Step 10: Be a good teacher

We can divide these 10 steps into two major parts
* The first part, from step one to step six, only needs to be executed once from start to finish
* The second part, from step seven to step ten, needs to be executed repeatedly

The first part involves searching and filtering input resources, and defining targets. Here are some things to note:

Find out what the **main uses of the actual application** are:
For example, with sed, you'll find that its main use cases are for adding, deleting, modifying, and querying text and stream data. For these common cases, you can get a rough idea by scanning related materials. If you don't know how to effectively acquire information, you can read my article [How I Acquire Knowledge and Information](/post/softskills/how_do_i_acquire_knowledge_and_information/)

Define an **executable target**: 
You need to define an executable target, for example, for sed, I need to rewrite all the use cases in `tldr sed`. For `awk`, my goal is to use `awk` to find the value of a certain field in yaml.

Filter **enough materials needed to achieve the target**:
When you find some good materials through a search engine, you can filter out the materials that will allow you to achieve your goal after reading, i.e., the most common use materials. Although they may be rough, you will find the materials you really need more precisely in your practice later.

The second part is to **practice while checking the documentation and output insights**:
In fact, my method for quickly learning technology has always been to do it hands-on and practice more. When I first graduated, I liked to learn a technical knowledge point in a "from cover to cover" way, but as time became less and less, I no longer had the energy to read a book from beginning to end.

So, learning in a way that practices while checking the documentation is more efficient, and it also conforms to the idea of the learning pyramid.

![Learning Pyramid](/image/the_cone_of_learning.png)

If you only read to learn a knowledge point, you can only absorb 10% of the content, but if you learn by teaching and playing, you can absorb 90% of the content. To give a simple example, when I was in high school, I played Hearthstone, which has 300+ classic cards, but I could recite 90% of the cards' stats and effects. I didn't deliberately remember them, but because I liked playing, I learned all these cards.

So, it's very important to **learn in a playful way**, to practice rather than just read the documentation.
Similarly, **teaching is a better way to learn**, because you can consolidate and confirm that your knowledge points are correct at the same time. I wrote this article to better consolidate my knowledge of the 80/20 rule and awk.

After practicing the more useful 20% of the knowledge points, when you are practicing, you can use the documentation to use these features more accurately when you encounter some niche features, avoiding you getting lost in the complicated details.

Below I will give two examples to illustrate this method:

# Learning awk

First, we understand what kind of tool awk is by skimming the documentation:

`Awk is an extremely versatile programming language for working on files.`

Awk is actually a programming language for processing text, which can explain why when you try to solve text processing problems from stackoverflow, many answers give awk examples that are not so simple and clear, the reason is that it is a programming language, not like grep Just add a few command line parameters to search for text.

## Find the most common use

I use `tldr` to find the most common use of this command. `tldr` simplifies the popular `man` pages through actual examples.
His output is as follows:

```
awk

A versatile programming language for working on files.
More information: https://github.com/onetrueawk/awk.

- Print the fifth column (a.k.a. field) in a space-separated file:
awk '{print $5}' filename

- Print the second column of the lines containing "foo" in a space-separated file:
awk '/foo/ {print $2}' filename

- Print the last column of each line in a file, using a comma (instead of space) as a field separator:
awk -F ',' '{print $NF}' filename

- Print all lines where the 10th column value equals the specified value:
awk '($10 == value)'

- Sum the values in the first column of a file and print the total:
  awk '{s+=$1} END {print s}' filename
...
```

Through these examples, I can know what the common uses of awk are, and what syntax and parameters are the most important.

The main uses are:
1. Print a column in the file
2. Find the corresponding row based on a certain value
3. Split a row into multiple fields based on a field separator
4. Print rows that meet certain conditions

According to the example, we can understand that the -F parameter is quite useful, and the `print` keyword and variables starting with `$` are also quite useful.

We also have some doubts:
* What does `'{print $5}'` syntax mean?
* Why does `'/foo/ {print $2}'` print the second column of the row containing "foo" in a space-separated file?

## Find learning resources

With these questions and the common cases we understand, we can find related resources through search engines:

- https://www.eriwen.com/tools/awk-is-a-beautiful-tool/ A short blog about awk, talking about some philosophy
- `man awk` man manual
- `tldr awk` tldr awk
- https://www.gnu.org/software/gawk/manual/gawk.html#Getting-Started 
- https://www.geeksforgeeks.org/awk-command-unixlinux-examples/ tutorial
- https://www.runoob.com/linux/linux-comm-awk.html tutorial
- [Summary of AWK Commands](https://www.grymoire.com/Unix/Awk.html#toc-uh-13) Brief introduction
- https://sparky.rice.edu//~hartigan/awk.html How to use awk

We found 8 related resources, including a very long user manual, but don't worry, we won't read it all, just skim through the structure to know what content is in which chapters. I will filter it later.

## Setting Goals

Then it's about setting learning goals, note that this goal must be **executable**. If you have used OKR or GTD, then you will basically understand what it is like.
The key result of OKR is a measurable result for this goal, or each small task of the GTD execution list, which is executable and measurable.

In this example, I mainly set 3 goals:

* The first is to ensure that I can write out the examples in tldr by handwriting, because this example is the most commonly used case
* The second is to format the average total score of the students below:
    ```
    Marry   2143 78 84 77
    Jack    2321 66 78 45
    Tom     2122 48 77 71
    Mike    2537 87 97 95
    Bob     2415 40 57 62
    ```
  The result will be like this
  ```
  NAME    NO.   MATH  ENGLISH  COMPUTER   TOTAL
  ---------------------------------------------
  Marry  2143     78       84       77      239
  Jack   2321     66       78       45      189
  Tom    2122     48       77       71      196
  Mike   2537     87       97       95      279
  Bob    2415     40       57       62      159
  ---------------------------------------------
  TOTAL:       319      393      350
  AVERAGE:     63.80    78.60    70.00
  ```
* The last is to find the value of a field in yaml through awk, which is more difficult but interesting, [Parse a YAML section using shell](https://unix.stackexchange.com/questions/608137/parse-a-yaml-section-using-shell)

You can see that these three goals are executable and the results are easy to measure.
## Filtering Learning Resources

After setting the goals, we can filter out relevant resources based on the goals:

I filtered out the following resources:
[awk is a beautiful tool](https://www.eriwen.com/tools/awk-is-a-beautiful-tool/), man page,
[Executing awk scripts](https://www.grymoire.com/Unix/Awk.html#toc-uh-2),[awk syntax](https://www.grymoire.com/Unix/Awk.html#toc-uh-13),
[awk regular expression && conditional expression](https://www.grymoire.com/Unix/Awk.html#toc-uh-11)

## Skim through the filtered materials

First, we can skim through the filtered materials:

I found that awk actually only operates one record at a time, this record is a line by default. At the same time, it will extract each string separated by spaces (default) in each line as each field.

This can explain that `$5` in `'{print $5}'` is actually the 5th field separated by spaces in each line. And using `-F` can replace the string used for separation from space to the specified string.

`awk -F ','` This is to use a comma to separate fields.

## Learning to Use

### Reproduce the examples in tldr
At this time, you can open your command line and start playing with `awk`, you will find 

`awk '/foo/ {print $2}' filename` This syntax is very interesting.

By consulting the documentation, you actually find that /foo/ can be replaced with various regular expressions:

For:

```
Marry	2143	78	84	77
Jack	2321	66	78	45
Tom	2122	48	77	71
Mike	2537	87	97	95
Bob	2415	40	57	62
```
You can use this method to print out lines containing /Bob/
`awk '/Bob/ {print $0}'  sheet` 

Using `awk '/m$/'` can print out lines with fields ending in m, that is, lines containing Tom.

By reading the chapter on regular expressions in the man manual `Regular expressions`

`awk '/m$/' {print $0}` is actually a shorthand for `awk $0 ~ '/m$/ {print $0}'`.

It means that when the input record (default is line), if the fields match this expression, print out the current line.


So we will find that the case in `tldr` is wrong
```
foo bar ggg
bar foo ggg
```

```
- Print the second column of the lines containing "foo" in a space-separated file:
awk '/foo/ {print $2}' filename
```

The correct one should be `awk '$2 ~ /foo/ {print $2}'`, when `$2 ~ /foo/` matches, it will be assigned to 1, and when it does not match, it will be assigned to 0.
That is, when it matches, this line of record processing will become `awk '1 {print $2}` , and when it does not match, it will become `awk '0 {print $2}` .


### Implement the formatting of student grades

To implement the formatting of student grades, you need to introduce the `awk` script, which can be read from the filtered materials.
To sum up, -f can specify the awk script, the first line of the file needs to be `#!/bin/awk -f`, and the subsequent script is the `awk` script.

The keywords of awk can also be found in the filtered documents. Playing while reading the documents can really effectively find important resources.

[Basic Structure](https://www.grymoire.com/Unix/Awk.html#toc-uh-1)

```awk
BEGIN { print "START" }
/foo/ { print         }
END   { print "STOP"  }
```

From the above example, it can be seen that what is important about awk is that this pattern specifies the behavior to be executed with each line read as input.
If the preceding expression is true, execute the code in `{ print }`.
If there is no expression before, it will match the content in each line by default.
In addition, BEGIN and END are two other important patterns.
As you would expect, these two words specify the operations to be performed before reading any lines and after reading the last line.

Understanding this can achieve this small goal:

```awk
#!/bin/awk -f
BEGIN {
math=0
english=0
art=0
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", "Name", "No.", "MATH", "ENGLISH","ART","TOTAL"
}
{
	math+=$3
	english+=$4
	art+=$5
	cnt+=1
	total=$3+$4+$5
	sum+=total
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", $1, $2,$3,$4,$5,total
}
END  {
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", "TOTAL","", math,english,art,total
printf "%-6s %-6s %-6s %-6s %-6s %-6s\n", "AVG","", math/cnt, english/cnt,art/cnt,sum/cnt
}
```

### Use awk to find the value of a field in yaml

This answer on Stackoverflow is baffling: 
```
something:
 - whatever:
   - something
 - toc: 4
 - body: assets/footer.html
pkg:
 - pkg_a_1:
   - Shass
   - AJh55
   - ASH7
 - pkg_b_1:
   - Kjs6
   - opsaa
other:
morestuff:
 - whatever
```

Need to get the value of pkg_a_1, output like this:
```
pkg_a_1 Shass
pkg_a_1 AJh55
pkg_a_1 ASH7
pkg_b_1 Kjs6
pkg_b_1 opsaa
```

The given answer is `awk '/^[^ ]/{ f=/^pkg:/; next } f{ if (sub(/:$/,"")) pkg=$2; else print pkg, $2 }' file`

Just looking at the answer is a bit confusing, isn't it? Let's break down the input:

* `/^[^ ]/` matches all non-empty lines.
* `f=/^pkg:/` does a match on the current line, if it matches, f becomes 1, otherwise f becomes 0.
  ```
  xiantang@ubuntu:~$ awk '/^[^ ]/{ f=/^pkg:/;print f}' ymal
    0
    1
    0
    0
  ```
* next means to skip the current line and continue parsing the following lines.
* The following f is a flag, if f is 1, perform the following behavior.
* The final assignment operation is self-explanatory.

If I want to read the value of something.body, for example, this output

`something.body assets/footer.html`

You can use `awk '/^[^ ]/{ f=/^something/;sub(/:/,".",$0);prefix=$0;  next } f{ b=/body/;} f&&b{printf "%s%s %s\n", prefix,$2,$3}' ymal`

`something.body: assets/footer.html`

This way, we have achieved our three small goals for awk. Remember to practice while reviewing the documentation, and try different behaviors. Only when you try, you truly learn.

# Conclusion

This article explains how to find information and how to filter information by setting goals, as well as how to quickly learn knowledge through practice. It also gives an example of learning awk to practice this method. This method is applicable to 80% of learning scenarios. Don't forget to share after you have achieved something!
