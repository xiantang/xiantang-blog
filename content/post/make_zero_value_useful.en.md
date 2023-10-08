---
title: "Golang: Making Your Zero Values More Useful"
date: 2022-01-16T15:04:40+08:00
author: "xiantang"
# lastmod: 
tags: ["Chinese", "Golang"]
categories: ["Golang"]
images:
  - ./post/make_zero_value_useful.png
description: Golang uses zero values to make your code more concise, including Golang json zero value, Golang map zero value, etc.
draft: false
---


<!-- 
* Always start with a sentence to synchronize the background and context
* Comment-style writing quotes some big cows
* More interesting jump links
* Recommend some interesting links at the end of the article
* Write the outline first, then the content -->

> Make the zero value useful.
                        --Go Proverbs

Let's start with the Golang blog: [The zero value](https://go.dev/ref/spec#The_zero_value)
> When memory is allocated to store a value, whether by declaration or by calling make or new, and no explicit initialization is provided, the memory is given a default initialization. Each element of this value is set to its type's zero value: false for booleans, 0 for integers, 0.0 for floats, `""` for strings, and nil for pointers, functions, interfaces, slices, channels, and maps. This initialization is done recursively, so, for example, if no value is specified, each element of a structure array will be zeroed.

Setting a value to zero in this way provides a great guarantee for the safety and correctness of the program, and also ensures the readability and simplicity of the program. This is what Golang programmers call "Make the zero value useful".

## Zero value cheat sheet

| Type | Zero Value |
| --- | --- |
| bool | false |
| int | 0 |
| float | 0.0 |
| string | "" |
| pointer | nil |
| function | nil |
| slice | nil |
| map | nil |
| channel | nil |

The initialization of zero values is recursive, so if no value is specified, each element of the structure array will be zeroed.

```golang
➜ gore --autoimport  
gore version 0.5.3  :help for help
gore> var a [10]int
gore> a
[10]int{
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
}
```

The same is true for structures. We initialize a B structure that references A, and if no value is specified, each field of B will be zeroed.

```golang
➜ gore --autoimport
gore version 0.5.3  :help for help
gore> type A struct { i int; f float64 }
gore> type B struct { i int; f float64; next A }
gore> new(B)
&main.B{
  i:    0,
  f:    0.000000,
  next: main.A{
    i: 0,
    f: 0.000000,
  },
}
```

note:

* new: new(T) returns a pointer to the `zero value` of the newly allocated T type.
* The tool used is [gore](https://github.com/x-motemen/gore)

## Usage of Zero Values

The previous section has introduced what zero values are, here we will see how to use them.

### sync.Mutex

Here is an example of sync.Mutex, sync.Mutex is designed to be used directly through zero values without explicit initialization.

```golang
package main

import "sync"

type MyInt struct {
        mu sync.Mutex
        val int
}

func main() {
        var i MyInt

        // i.mu is usable without explicit initialisation.
        i.mu.Lock()      
        i.val++
        i.mu.Unlock()
}
```

Thanks to the characteristics of zero values, the two unexported variables inside Mutex will be initialized to zero values. So the zero value of sync.Mutex is an unlocked Mutex.

```golang
// A Mutex is a mutual exclusion lock.
// The zero value for a Mutex is an unlocked mutex.
//
// A Mutex must not be copied after first use.
type Mutex struct {
 state int32
 sema  uint32
}
```

### bytes.Buffer

Another example is bytes.Buffer, its zero value is an empty Buffer.

```golang
package main

import "bytes"
import "io"
import "os"

func main() {
        var b bytes.Buffer
        b.Write([]byte("go go go"))
        io.Copy(os.Stdout, &b)
}
```

### JSON omitempty

JSON receivers also accept the `omitempty` flag, when the input field is a `zero value`, the receiver will ignore this field.

```golang
➜  gore --autoimport          
gore version 0.5.3  :help for help
gore> type Person struct {
.....         Name string `json:"name"`
.....         Age  int    `json:"age"`
.....         Addr string `json:"addr,omitempty"`
..... }
gore> p1 := Person{
.....             Name: "taoge",
.....             Age:  30,
.....     }
main.Person{
  Name: "taoge",
  Age:  30,
  Addr: "",
}
gore> data, err := json.Marshal(p1)
...
gore> string(data)
"{\"name\":\"taoge\",\"age\":30}"
```

### channel close

In [Channel Axioms](https://dave.cheney.net/2014/03/19/channel-axioms), there is also a rule related to zero values, when the channel is closed, the <- operation on the closed channel always returns `zero value` immediately.

```golang
package main

import "fmt"

func main() {
         c := make(chan int, 3)
         c <- 1
         c <- 2
         c <- 3
         close(c)
         for i := 0; i < 4; i++ {
                  fmt.Printf("%d ", <-c) // prints 1 2 3 0
         }
}
```

The correct way to solve the above problem is to use a for loop:

```golang
for v := range c {
         // do something with v
}

```

### Value not found for corresponding key in map

For a map, if the corresponding key is not found, the map will return a zero value of the corresponding type.

```golang
➜ gore --autoimport
gore version 0.5.3  :help for help
gore> a := make(map[string]string)
map[string]string{}
gore> a["123"] = "456"
"456"
gore> a["000"]
""
```

The solution to this problem is to return multiple values:

```golang
gore --autoimport
gore version 0.5.3  :help for help
gore> a := make(map[string]string)
map[string]string{}
gore> c,ok := a["000"]
""
false
```

For non-existent keys, the value of ok will become false.

## Summary

The above is some experience summary about `zero value`. I hope everyone can use the `zero value` better when designing code, and use the features provided by `zero value` to initialize some variables.

## Related Links

* [Golang zero value](https://dave.cheney.net/2013/01/19/what-is-the-zero-value-and-why-is-it-useful)
* [《Channel Axioms》](https://dave.cheney.net/2014/03/19/channel-axioms)
* [Go REPL](https://github.com/x-motemen/gore)

## Article Recommendations

Finally, I would like to share with you some good articles I have been reading recently. I wanted to send them in a weekly format, but because I read them in a scattered way, I put them at the end of each blog post, hoping everyone can gain something.

* [Why we don't have children](https://shuxiao.wang/posts/why-no-new-baby/) Some thoughts about having children
* [Detailed interpretation of the paper "The Tail At Scale"](https://blog.csdn.net/LuciferMS/article/details/122522964)
* [Writing maintainable Go code](https://jogendra.dev/writing-maintainable-go-code) Many points resonate with me after practice. The code is written once, but it will be read hundreds of times, so writing maintainable code is very important.
* [Advanced Golang concurrency programming talk](https://go.dev/blog/io2013-talk-concurrency) The sharer provides actual concurrency problems and then gives some of his own solutions. Very beneficial.
* [pprof graphic explanation](https://github.com/google/pprof/blob/master/doc/README.md#interpreting-the-callgraph) Finally, I can read pprof.

Sure, please provide the Markdown content you want to translate. I'll make sure to follow the rules you've outlined.
