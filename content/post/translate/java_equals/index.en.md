---
title: "How to distinguish between == and .equals() method in Java"
date: 2019-02-24T14:40:53+08:00
tags: ["java"]
categories: ["English"]
draft: false



---

Generally speaking, `equals()` and `"=="` operator are used to compare whether two objects are equal, but there are many differences between the two:

1. The main difference is that `.equals()` is a method, `==` is an operator.
2. Use `==` to compare references, referring to whether they point to the same memory address. Use `.equals()` to compare the content of objects, comparing values.
3. If `.equals` is not overridden, it will default to calling the nearest superclass to override this method.
4. Sample code:

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

Output:

```java
false
true
```

Explanation: Here we create two objects named `s1` and `s2`.

- `s1` and `s2` are references to different objects.
- When we use `==` to compare `s1` and `s2`, the return is `false`, because the memory space they occupy is different.
- When using `.equals()`, because only the value is compared, the result is `true`.

Let's understand the specific differences between these two:

#### Equal operator (==)

We can use the `==` operator to compare each primitive type (including boolean type), and it can also be used to compare [custom types (object types)](https://docs.oracle.com/cd/B14117_01/appdev.101/b10807/13_elems031.htm)

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

Output:

```java
false
false
true
true
```

If we use `==` to compare custom types, we need to ensure parameter type compatibility (either a subclass and superclass relationship, or the same type). Otherwise, we will produce a compile error.

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

Output:

```java
false
false
// error: incomparable types: Thread and String
```

#### .equals()

In Java, using `equals()` for `String` comparison is based on the data/content of the `String`, that is, the value. If all their contents are the same and are of `String` type, it will return `true`. If all characters do not match, it will return `false`.

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

Output:

```java
true
false
false
true
```

Explanation: Here we use the `.equals` method to check whether two objects contain the same value.

- In the above example, we created 3 thread objects and two string objects.
- In the first comparison, we compare whether `t1==t3`, as we all know, the reason for returning true is because t1 and t3 are references to the same object.
- When we use `.equals()` to compare two `String` objects, we need to determine whether the two objects have the same value.
- The `String` `"GEEKS"` object contains the same `"GEEK"`, so it returns `true`.

Article author: Bishal Kumar Dubey
Translator: [xiantang](https://github.com/xiantang)
Original article address: [Difference between == and .equals() method in Java](https://www.geeksforgeeks.org/difference-equals-method-java/)
