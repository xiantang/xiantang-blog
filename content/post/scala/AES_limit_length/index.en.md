---
title: "AES Requires Limiting SEED Length"
date: 2019-10-20T01:37:56+08:00
lastmod: 2019-10-20T01:37:56+08:00
draft: false
tags: ["scala"]
categories: ["English","scala"]
author: "xiantang"



---

I wrote a utility class to encrypt and decrypt the app field in the database

There are no problems running unit tests in the local environment, but bugs appear in the production environment.

![image-20191109145633818](../images/image-20191109145633818.png)

The reason for this is that the online environment does not support the AES algorithm Provider. It needs to be solved by adding a third-party package that supports it under the ext package or introducing a third-party library.

I chose to introduce a third-party library:

```scala
"org.bouncycastle" % "bcprov-jdk16" % "1.45"
```

```scala
private val localCipher: ThreadLocal[Cipher] = ThreadLocal.withInitial(() => Cipher.getInstance("AES/ECB/PKCS5Padding", new BouncyCastleProvider()))
```

This solves the problem of No installed provider supports this key.

But when it comes to the test environment, there is another problem:

![image-20191109150457772](../images/image-20191109150457772.png)

It shows that there is no valid AES key

First, I set the length of SEED to 16 characters. There is no problem locally, but the test environment still reports an error. I suddenly found that my SEED will undergo a SHA-256 algorithm hash, and then its number of characters will increase to 32.

We need to clarify the differences between the local environment and the online environment:

* Local: The Jdk security directory contains unlimit jar packages, which support 16 24 32 bit keys
* Online: The Jdk security directory only contains limit jar packages, which only support 16-bit keys

There are two solutions: 1. Install unlimit jar packages online 2. Use 16-bit keys

Since it's difficult to change the jdk jar package in the online container environment, the second method is adopted.

All you need to do is change the hash algorithm for SEED encryption to MD5 encryption, because MD5 will convert SEED into a string of 16 characters.

```groovy
import java.nio.charset.StandardCharsets
import java.security.MessageDigest

String a = "----------------"
def instance = MessageDigest.getInstance("MD5")
secret = instance.digest(a.getBytes())
new String(secret).length()
```
