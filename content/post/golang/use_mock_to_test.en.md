---
title: "Using Mock and Interface for Golang Unit Testing"
date: 2022-01-07T01:37:56+08:00
lastmod: 2022-01-07T01:37:56+08:00
draft: false
tags: ["Golang"]
categories: ["Golang"]
author: "xiantang"
images:
   - ./post/golang/cover.png
description: "Best practices for golang unit testing Go language Automated testing golang unit testing database golang unit testing mock golang unit testing standards"

---

<!-- * Always start with a sentence to sync the background and context
* Comment-style [[writing]] quotes some words from the big cows
* More interesting jump links
* Write the outline first, then the content -->

<!-- ## A sentence to lead out the article -->

> At work, I often find that many engineers' `Golang` unit tests are problematic, just simply calling code for output, and it will include various `IO` operations, making the unit test unable to run everywhere.

## Using Mock and Interface for Golang Unit Testing

This article will introduce how to do unit testing correctly in `Golang`.

### What is unit testing? Characteristics of unit testing

Unit testing is a very important part of quality assurance. Good unit tests can not only find problems in time, but also facilitate debugging and improve production efficiency. Therefore, many people think that writing unit tests requires extra time and will reduce production efficiency. This is the biggest prejudice and misunderstanding about unit testing.

Unit tests will isolate the corresponding test modules for testing, so we should remove all related external dependencies as much as possible and only conduct unit tests on related modules.

So what you see in the business code repository is that some of the unit tests that call `HTTP` in the `client` module are actually non-standard, because `HTTP` is an external dependency. If your target server has a fault, then your unit test will fail.

```go
func Test_xxx(t *testing.T) {
 DemoClient := &demo.DemoClient{url: "http://localhost:8080"}
 DemoClient.Init()
 resp := DemoCliten.DoHTTPReq()
 fmt.Println(resp)
}
```

In the above example, when `DemoClient` does the `DoHTTPReq` method, it will call the `http.Get` method. This method contains external dependencies, which means it will request the local server. If a new colleague just got your code and there is no such server locally, then your unit test will fail.

And in the above example, for the `DoHTTPReq` function, it just simply outputs, without checking the return value at all. If the internal logic is modified and the return value is changed, although your test can still `pass`, in fact, your unit test is not working.

From the above examples, we can summarize two characteristics of unit tests:

* They have no external dependencies, are as side-effect free as possible, and can run anywhere.
* They check the output.

Another point I want to mention is that the difficulty of writing unit tests is actually ranked:

UI > Service > Utils

So when writing unit tests, we will prioritize unit tests for `Utils` because `Utils` will not have too many dependencies. Next is the unit test for `Service`, because the unit test for `Service` mainly depends on upstream services and databases, and only needs to separate dependencies to test logic.

So how to separate dependencies? Let's move on to the next section, where we will introduce how to separate dependencies.

### What is Mock?

For `IO` dependencies, we can use `Mock` to simulate data, so we don't have to worry about unstable data sources.

So what is `Mock`? And how do we `Mock`? Think about a scenario where you and your colleagues are developing a collaborative project. Your progress is relatively fast and you are almost done with your development, but your colleague's progress is slightly slower, and you also depend on his service. How do you not `block` your progress and continue development?

Here you can use `Mock`, that is, you can agree with your colleague in advance on the data format to be interacted with. In your test code, you can write a client that can generate the corresponding data format, and these data are all fake, then you can continue to write your code. When your colleague has completed his part of the code, you only need to replace `Mock Clients` with real `Clients`. This is the role of `Mock`.

Similarly, we can also use `Mock` to simulate the data that the module to be tested depends on. Here is an example:

```go
package myapp_test
// TestYoClient provides mockable implementation of yo.Client.
type TestYoClient struct {
    SendFunc func(string) error
}
func (c *TestYoClient) Send(recipient string) error {
    return c.SendFunc(recipient)
}
func TestMyApplication_SendYo(t *testing.T) {
    c := &TestYoClient{}
    a := &MyApplication{YoClient: c}
    // Mock our send function to capture the argument.
    var recipient string
    c.SendFunc = func(s string) error {
        recipient = s
        return nil
    }
    // Send the yo and verify the recipient.
    err := a.Yo("susy")
    ok(t, err)
    equals(t, "susy", recipient)
}
```

We will have a `MyApplication` and it also depends on a reporting `YoClient`. In the above code, we will replace the dependent `YoClient` with `TestYoClient`. So when the code calls `MyApplication.Yo`, what it actually executes is `TestYoClient.Send`, so we can customize the input and output of external dependencies.

You can also find an interesting point, that is, we replace the `SendFunc` of `TestYoClient` with `func(string) error`, so we can control the input and output more flexibly. For different tests, we only need to change the value of `SendFunc`. In this way, we can control the input and output at will for each test.

At this point, you may encounter another problem. If you want to successfully inject `TestYoClient` into `MyApplication`, the corresponding member variable needs to be the specific type `TestYoClient` or an interface type that satisfies the `Send()` method. However, if we use a specific type, we can't replace the real `Client` with the `Mock Client`.

So we can use the interface type to replace it.

### What is Interface?

Interfaces in `Golang` may be different from the interfaces you have encountered in other languages. In `Golang`, an interface is a collection of functions. And `Golang` interfaces are implicit, no explicit definition is required.

I personally agree with this design, because through multiple practices, I found that the pre-defined abstraction often cannot accurately describe the behavior of the specific implementation. So we need to abstract afterwards, instead of writing types to satisfy `interface`, we should write interfaces to meet usage requirements.

> Always *abstract* things when you actually need them, never when you just foresee that you need them.

My personal recommendation is that for several similar processes, we can first organize the code by writing several structs, and then when we find that these structs have similar behaviors, we can abstract an interface to describe these behaviors, which is the most accurate.

At the same time, the number of methods contained in the `Golang` interface also needs to be limited, not too many, 1-3 methods are enough. The reason is that if your interface contains too many methods, it will be troublesome to add a new implementation type code, and such code is not easy to maintain. Similarly, if your interface has many implementations and many methods, it will be difficult to add another function to the interface, you need to implement these methods in each struct.

Back to the topic, for `YoClient`, if we didn't adopt the `TDD` method at the beginning, then what `MyApplication` depends on must be a formal specific type. At this time, we can write a `TestYoClient` type instance in the test code, extract the common functions to abstract the interface, and then replace the `YoClient` in `MyApplication` with the interface type.

This can achieve our goal.

```go
package myapp
type MyApplication struct {
    YoClient interface {
        Send(string) error
    }
}
func (a *MyApplication) Yo(recipient string) error {
    return a.YoClient.Send(recipient)
}
```

### Some other examples

In addition, I have provided an example for reference, mainly found from the official production code, an example that masks sensitive information.

This example is a `mock` of the external dependency `etcd`.

```golang
type ETCD interface {
 GetWithTimeout(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error)
 Watch(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan
}

type MockEtcdClient struct {
 GetWithTimeoutFunc func(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error)
 WatchFunc          func(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan
}

func (m MockEtcdClient) GetWithTimeout(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error) {
 return m.GetWithTimeoutFunc(key, opts...)
}

func (m MockEtcdClient) Watch(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan {
 return m.WatchFunc(ctx, key, opts...)
}

```

An example of a unit test:

```go
func Test_saveTestConf(t *testing.T) {
 etcd := store.MockEtcdClient{
  GetWithTimeoutFunc: func(key string, opts ...clientv3.OpOption) (*clientv3.GetResponse, error) {
   return &clientv3.GetResponse{
    Kvs: []*mvccpb.KeyValue{
     {
      Key:   []byte("/xxxx/xxx/config"),
      Value: []byte("{\"xxx\":\"xxx\"}"),
     },
    },
   }, nil
  },
  WatchFunc: func(ctx context.Context, key string, opts ...clientv3.OpOption) clientv3.WatchChan {
   return nil
  },
 }

 configKey, err := saveTestConf(etcd ,"xxxx", "/xxxx/xxx/config")
 if err != nil {
  t.Error(err)
 }
 assert.Equal(t, "/xxxx/xxx/config", configKey)
}


```

### other tips

I have some little tricks about testing that you might not know

#### golang's internal and external testing

For a package's exported methods and variables, you can create a `test` file in the same package to test, just change the package suffix to `_test`. This can achieve `black box testing`. The advantage is that you can describe your test from the perspective of the caller, rather than writing your test from the internal perspective. It can also serve as an example for users to see how to use it.

```go
// in example.go
package example

var start int

func Add(n int) int {
  start += n
  return start
}

// in example_test.go
package example_test

import (
 "testing"

 . "bitbucket.org/splice/blog/example"
)

func TestAdd(t *testing.T) {
  got := Add(1)
  if got != 1 {
    t.Errorf("got %d, want 1", got)
  }
}
```

In addition, you can also test unexported methods and variables, you can create a file with a suffix of `_internal_test` to indicate that you want to test unexported methods and variables.

## Conclusion

* Characteristics of `Golang` unit tests:
  * No external dependencies, try to have no side effects, can run everywhere
  * Need to check the output
  * Can serve as an example for users to see how to use

* `Golang` can use interfaces to replace dependencies

### Interesting link recommendations

Finally, I would like to share with you the links I referred to, as well as some good articles I have been reading recently. Since I read them in a scattered way, I wrote them all for you, hoping that you can gain something.

* [How to mock file system](https://talks.golang.org/2012/10things.slide#8)
* [How to write a mock struct](https://medium.com/@benbjohnson/structuring-tests-in-go-46ddee7a25c) It's really convenient to reuse through function variables
* [Lesser-known testing techniques](https://splice.com/blog/lesser-known-features-go-test/)
* [How to achieve financial freedom without trying](https://geekplux.com/newsletters/2) Making money is always the theme
* [gopher-reading-list](https://github.com/enocom/gopher-reading-list) I've learned a lot from reading through it
* [What “accept interfaces, return structs” means in Go](https://medium.com/@cep21/what-accept-interfaces-return-structs-means-in-go-2fe879e25ee8) Always [abstract] things when you actually need them, not when you just foresee that you need them.
* [Discussion on house prices on Tianya](https://github.com/xiantang/kkndme_tianya)

Sure, please provide the Markdown content you want to translate.
