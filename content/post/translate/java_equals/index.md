---
title: "Java 如何区分==与.equals()方法"
date: 2019-02-24T14:40:53+08:00
tags: ["java"]
categories: ["中文"]
draft: false



---





一般来说`equals()`和`"=="`运算符是用来比较两个对象是否相等，但是这两者之前还是有许多不同：

1. 最主要的不同是`.equals()`是方法，`==`是运算符。
2. 使用`==`来进行引用的比较,指的是是否指向同一内存地址。使用`.equals()`来进行对象内容的比较，比较值。
3. 如果没有重写`.equals`就会默认调用最近的父类来重写这个方法。
4. 示例代码:

```java
// Java program to understand  
// the concept of == operator 
public class Test { 
    public static void main(String[] args) 
    { 
        String s1 = new String("HELLO"); 
        String s2 = new String("HELLO"); 
        System.out.println(s1 == s2); 
        System.out.println(s1.equals(s2)); 
    } 
} 
```

输出:

```java
false
true
```

解释: 这里我们创建了两个对象分别命名为`s1`和`s2`。

- `s1`和`s2`是指向不同对象的引用。
- 当我们使用`==`来比较`s1`和`s2`时，返回的是`false`,因为他们所占用的内存空间不一样。
- 使用`.equals()`时，因为只比较值，所以结果时`true`。

我们来分别理解一下这两者的具体区别:

#### 等于运算符(==)

我们可以通过`==`运算符来比较每个原始类型(包括布尔类型),也可以用来比较[自定义类型(object types)](https://docs.oracle.com/cd/B14117_01/appdev.101/b10807/13_elems031.htm)

```java
// Java program to illustrate  
// == operator for compatible data 
// types 
class Test { 
    public static void main(String[] args) 
    { 
        // integer-type 
        System.out.println(10 == 20); 
  
        // char-type 
        System.out.println('a' == 'b'); 
  
        // char and double type 
        System.out.println('a' == 97.0); 
  
        // boolean type 
        System.out.println(true == true); 
    } 
} 
```

输出:

```java
false
false
true
true
```

如果我们使用`==`来比较自定义类型，需要保证参数类型兼容(compatibility)(要么是子类和父类的关系，要么是相同类型)。否则我们会产生编译错误。

```java
// Java program to illustrate  
// == operator for incompatible data types 
class Test { 
    public static void main(String[] args) 
    { 
        Thread t = new Thread(); 
        Object o = new Object(); 
        String s = new String("GEEKS"); 
  
        System.out.println(t == o); 
        System.out.println(o == s); 
  
       // Uncomment to see error  
       System.out.println(t==s); 
    } 
} 
```

输出:

```java
false
false
// error: incomparable types: Thread and String
```

#### .equals()

在Java中，使用`equals()`对于`String`的比较是基于`String`的数据/内容，也就是值。如果所有的他们的内容相同，并且都是`String`类型，就会返回`true`。如果所有的字符不匹配就会返回`false`。

```java
public class Test { 
    public static void main(String[] args) 
    { 
        Thread t1 = new Thread(); 
        Thread t2 = new Thread(); 
        Thread t3 = t1; 
  
        String s1 = new String("GEEKS"); 
        String s2 = new String("GEEKS"); 
  
        System.out.println(t1 == t3); 
        System.out.println(t1 == t2); 
  
        System.out.println(t1.equals(t2)); 
        System.out.println(s1.equals(s2)); 
    } 
} 
```

输出:

```java
true
false
false
true
```

解释:这里我们使用`.equals`方法去检查是否两个对象是否包含相同的值。

- 在上面的例子中，我们创建来3个线程对象和两个字符串对象。
- 在第一次比较中，我们比较是否`t1==t3`,众所周知,返回true的原因是因为t1和t3是指向相同对象的引用。
- 当我们使用`.equals()`比较两个`String`对象时，我们需要确定两个对象是否具有相同的值。
- `String` `"GEEKS"` 对象包含相同的`“GEEK”`，所以返回`true`。

本文作者:Bishal Kumar Dubey
译者:[xiantang](https://github.com/xiantang)
原文地址:[Difference between == and .equals() method in Java](https://www.geeksforgeeks.org/difference-equals-method-java/)
