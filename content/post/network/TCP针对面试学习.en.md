---
title: "TCP Study for Interviews"
date: 2020-04-01T01:37:56+08:00
lastmod: 2020-04-01T01:37:56+08:00
draft: false
tags: ["network"]
categories: ["English","network"]
author: "xiantang"



---

# What is TCP

1. TCP is a full-duplex, byte-stream protocol based on the IP protocol.
2. TCP provides end-to-end accurate transmission.
   1. Acknowledges each byte
   2. Handles poor network conditions
      1. Timeout retransmission
      2. Congestion control
   3. Efficiency improvement
      1. Uses sliding window protocol
3. TCP is a connection-oriented protocol.

Since it is connection-oriented, how is this connection established?

That is, the following question is how to establish a virtual link using a three-way handshake.

### How does the three-way handshake happen

### Detailed operation

![image-20200331164958404](https://tva1.sinaimg.cn/large/00831rSTly1gde7c4z6xrj30wn0u0tal.jpg)

I took a picture from the high-efficiency code, let's talk about the process of the three-way handshake:

* Machine A first calculates a seq index x to indicate the position of the current data packet and the packet is marked as SYN.
* Machine B receives this packet and stores the data in the packet in its own buffer. Since the size of this packet is 1 byte, the index of the buffer is x + 1 synchronized to the seq position of the other party, returns a packet marked with SYN and ACK, and sends its own seq index y and tells the other party that it has received this data packet, so ack + 1.
* Machine C receives this packet with ACK and SYN and needs to return an ACK to indicate that it can receive the other party's packet, so it sends an ACK and its current send seq and its receive seq.

### Why shake hands three times

As for why to shake hands three times

There are mainly two points:

#### Ensure data parity

1. First, it is necessary to ensure that the seq of both parties is the index of each other's reception and transmission buffer

2. Ensure each other's reception and transmission capabilities

   The third handshake can guarantee the reporting ability of machine B and the receiving ability of machine A

   ![image-20200331170448728](https://tva1.sinaimg.cn/large/00831rSTly1gde7c5z93tj316y0d6ju3.jpg)

#### Preventing Dirty Connections

![image-20200331171058004](https://tva1.sinaimg.cn/large/00831rSTly1gde7c5ma90j30u00yidiz.jpg)

Machine A sends a SYN packet to Machine B, but this packet is not sent in time due to network reasons, and because the TCP timeout is less than TTL, if the TCP timeout is too long, the efficiency of resending packets will be slow.

So Machine A will send another TCP and establish a connection, at this time this packet has arrived at Machine B.

Machine B re-establishes the connection and returns an ACK to Machine A.

If there are only two handshakes, from the perspective of Machine B, the connection has been established, but when Machine A receives the Ack from Machine B, it is discarded directly because it is not SYN_SEND, and Machine B cannot perceive it, so Machine B has a unilateral dirty connection.

In the case of three handshakes, Machine B needs an ACK from Machine A to ensure its own sending ability and also avoid dirty connections. Machine A will not send ACK to Machine B, so from Machine B's perspective, there will be no connection.

### How does the four-way handshake occur

### Detailed Operation

![image-20200331174147939](https://tva1.sinaimg.cn/large/00831rSTly1gde7c6fwquj30v90u0di1.jpg)

Ensure that both parties have completed data processing.

* Machine A sends remaining data and FIN to Machine B and is in FIN_WAIT
* Machine B replies ACK to Machine A
* Machine B waits for a CLOSE_WAIT and then sends the remaining data to Machine A
* Machine A replies ACK indicating that the data has been received and waits for TIME_WAIT

### Why a four-way handshake is needed

It is necessary to ensure that both parties have completed data processing and that they both know it.

The third handshake is because Machine A tells Machine B that it cannot transmit data and after Machine B ACKs, Machine B needs to wait for the application program to do a process before it can send a FIN to tell Machine A that it cannot transmit data.

The fourth handshake is to tell Machine B that it has accepted the fact that Machine B cannot send requests.

### TCP keepalive vs Http keepalive

### HTTP

If keepalive = true is added to the Http header, multiple http requests will be on one TCP connection, and it will not handshake and wave as before for each request.

Advantages:

Reduce server load, under high concurrency servers, server load will decrease.

Reduce the time of each http request, because if it is an http request, there will be SSL or TSL behavior and three handshakes and four waves, so it will be slow, but it will not be like this if it is reduced to one connection.

### TCP

It is maintained by the OS, because each TCP connection has various timers, and TCP also has a keepalive timer. When the keepalive timer of TCP reaches 0, it will send a probe packet with ACK turned on to the other party, because TCP is a stream-oriented protocol. On the other hand, you will receive a reply from the remote host. And the data of these two packets is empty.

Advantages:

Determine whether the other party is a dead peer

Prevent disconnection due to network inactivity.
