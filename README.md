---
bibliography: references.bib
citation-style: nature.csl
header-includes: |
  ```{=tex}
  \renewcommand{\chapterheadstartvskip}{}
  ```
link-citations: true
title: System Design Notes
---

```{=tex}
\renewcommand{\chapterheadstartvskip}{}
```

-   [[1]{.toc-section-number}
    Introduction](#introduction){#toc-introduction}
    -   [[1.1]{.toc-section-number} A Gaming
        Server](#a-gaming-server){#toc-a-gaming-server}
    -   [[1.2]{.toc-section-number} All good things must come to an
        end](#all-good-things-must-come-to-an-end){#toc-all-good-things-must-come-to-an-end}
    -   [[1.3]{.toc-section-number} The Server slows
        down](#the-server-slows-down){#toc-the-server-slows-down}
    -   [[1.4]{.toc-section-number}
        Conclusion](#conclusion){#toc-conclusion}
-   [[2]{.toc-section-number} Storing
    Data](#storing-data){#toc-storing-data}
    -   [[2.1]{.toc-section-number} RAM vs
        Disk](#ram-vs-disk){#toc-ram-vs-disk}
    -   [[2.2]{.toc-section-number} Files](#files){#toc-files}
    -   [[2.3]{.toc-section-number} Speeding up
        writes](#speeding-up-writes){#toc-speeding-up-writes}
        -   [[2.3.1]{.toc-section-number} Batching
            Writes](#batching-writes){#toc-batching-writes}
        -   [[2.3.2]{.toc-section-number} Writing in
            Parallel](#writing-in-parallel){#toc-writing-in-parallel}
        -   [[2.3.3]{.toc-section-number} Writing to a Write Ahead
            Log](#writing-to-a-write-ahead-log){#toc-writing-to-a-write-ahead-log}
        -   [[2.3.4]{.toc-section-number} Do
            everything](#do-everything){#toc-do-everything}
-   [[3]{.toc-section-number} Querying
    Data](#querying-data){#toc-querying-data}
    -   [[3.1]{.toc-section-number} Relational
        Databases](#relational-databases){#toc-relational-databases}
    -   [[3.2]{.toc-section-number} NoSQL
        Databases](#nosql-databases){#toc-nosql-databases}
    -   [[3.3]{.toc-section-number} The Problems with Distributed
        Systems](#the-problems-with-distributed-systems){#toc-the-problems-with-distributed-systems}
-   [[4]{.toc-section-number} Indexing](#indexing){#toc-indexing}
    -   [[4.1]{.toc-section-number} The many kinds of
        indexes](#the-many-kinds-of-indexes){#toc-the-many-kinds-of-indexes}
    -   [[4.2]{.toc-section-number} The Venerable
        B-Tree](#the-venerable-b-tree){#toc-the-venerable-b-tree}
    -   [[4.3]{.toc-section-number} The Hash
        Index](#the-hash-index){#toc-the-hash-index}
    -   [[4.4]{.toc-section-number} Spatial
        Indexes](#spatial-indexes){#toc-spatial-indexes}
    -   [[4.5]{.toc-section-number} Inverted
        Indexes](#inverted-indexes){#toc-inverted-indexes}
-   [[5]{.toc-section-number} Serializing
    Data](#serializing-data){#toc-serializing-data}
    -   [[5.1]{.toc-section-number} Text Encodings (like
        JSON)](#text-encodings-like-json){#toc-text-encodings-like-json}
    -   [[5.2]{.toc-section-number} Binary Encodings (like
        Protobuf)](#binary-encodings-like-protobuf){#toc-binary-encodings-like-protobuf}
-   [[6]{.toc-section-number} Networking](#networking){#toc-networking}
    -   [[6.1]{.toc-section-number} How does the Internet
        work?](#how-does-the-internet-work){#toc-how-does-the-internet-work}
    -   [[6.2]{.toc-section-number} How do you have a distributed system
        with many
        nodes?](#how-do-you-have-a-distributed-system-with-many-nodes){#toc-how-do-you-have-a-distributed-system-with-many-nodes}
    -   [[6.3]{.toc-section-number} How do
        you](#how-do-you){#toc-how-do-you}
-   [[7]{.toc-section-number} References](#references){#toc-references}

# Introduction

Let's learn about how to make high scale websites. Each chapter will
start out with a story of a system to build, and the book will go into
depth about some of the trade-offs delved into. It's important to ask
clarifying questions, so we don't build the wrong thing, and to make
sure we meet the goals of the system, since technology exists to fulfill
needs in the real world.

## A Gaming Server

We'll start out with a smaller scale system for this chapter. Imagine
you want to play Minecraft with your friends, and have decided to host
your own server. Normally, you would have one of your friends host the
server, but that doesn't have enough availability for you. If the
assigned friend who owns the server data goes on vacation, they would
have to hand off the server data to another friend, and all your friends
have to update their settings to login to that server. As well, if the
first friend who runs the server goes on an unplanned vacation, the
server won't be running, so the rest of you can't play.

One of your friends could use an old computer as the server, but that
comes with its own issues -- they would need to somehow have a static
ip, and if the power goes out, they would have to turn back on the
server. Also, if the computer fails, or the hard drive fails, then the
server's data could be lost forever. Also, that friend would have to
always maintain a good enough internet connection for your friends to
connect to (lag is the enemy of all gamers, after all).

You've decided to rent out a Virtual Private Server (VPS), and pay
someone else to maintain the hardware, electricity, and internet
connection. This costs \$5 a month to get rid of all the headache of
managing the actual computer that will act as our server.

You ssh into the server, download the server software, set it up, allow
connections onto the required port, disallow connections to any other
ports, and you have yourself a working system. Congratulations!

## All good things must come to an end

After playing on the server has gone smoothly for months, one day, you
login to your beloved server and find that you have been "griefed". You
and your friends were trying to build a replica of the Space Station in
Minecraft, but it has been dynamited to smithereens. Who could've done
this? Sadly, Nobody knows.

Before pointing fingers, you remember that anybody can log into your
server, as you didn't require any authentication, so it doesn't have to
be one of your friends. That's a relief.

Secondly, to make sure nothing like this happens again, you start to
think about enabling audits on the server. You'd like to know who logs
in, and having every action they make jotted down, so you know who's a
nefarious actor to ban from the server if they do anything bad.

But that won't bring back the state of the server. You suggest creating
backups -- every day, you save the state of the server, and write it to
a file. This file is saved on the server, and an administrator can
rollback to any previous state. Since our server is pretty small, and we
have plenty of space for now, you store backups for a year.

Eventually the griefer comes back, trying to destroy your next creation,
a life sized replica of the Eiffel Tower. Your auditing catches them,
you ban the griefer, and roll back the state to before they could blow
up your half completed tower.

Wonderful. Now you can sleep peacefully.

## The Server slows down

Your system works well -- so well, in fact, that your friends start
referring their friends to join your server, and they refer their
friends too! You now have so many players at any given time that the
server you originally rented out is starting to lag during peak hours.
That's not good. You rent out a bigger computer from your VPS provider,
and everyone is happy for a bit. Until it happens again. You can't
afford a bigger computer, so you decide to dig in and learn more.

You need some analytics. You decide to install Grafana and Prometheus,
which provide metrics about your rented computer. You keep metrics for
14 days, so if one of your users notices bad performance, they can tell
you the time it happened and you can figure out what server statistics
correlates with bad performance.

You start by looking at Disk space, Disk I/O rate, CPU usage, and RAM
usage. You note that the reports correspond to high rates of Disk I/O.
With that information, you decide to upgrade your computer from a
standard hard drive to a solid state disk (SSD), so disk writes are much
faster.

## Conclusion

# Storing Data

## RAM vs Disk

Simplifying the memory of a computer, you can imagine that there are two
types of memory, volatile and non-volatile. Volatile memory does not
keep its state after it loses power. On the flip side, Non-volatile
memory keeps its state even without power.

In a computer, volatile memory is Random Access Memory (RAM), the memory
that is used by the computer as it runs programs. Non-volatile memory
would be a hard drive or an SSD. For a hard drive, a plate engraves the
physical bytes onto the disk, which allows it to save its state without
electricity. For an SSD, electricity is used to write to transistors
which keep the state of the drive in a way that allows it to survive
without continuous power.

We'll call volatile memory `RAM`, and non-volatile memory `Disk`.

## Files

The way state is saved on disk is with files. Files, when saved on a
disk drive, persist their data even after a shutdown. One way to use
this in system design is to save every change made onto disk. This
works, but is ill-performant. Saving a file in a persistent way on disk
requires a special system call on unix called `fsync`. This takes \~1ms
on an SSD[^1], or \~20ms on an HDD[^2]. On HDD backed computers, that
means **only** 50 writes per second can be persisted, no matter how fast
the CPU is. On an SSD, a slightly less abysmal 1000 writes can be saved
a second. For systems that never have to handle more persistent writes,
using fsyncs one after another works fine.

## Speeding up writes

You might wonder how planet scale companies scaled on commodity hardware
that used HDDs. There are a few ways: batching writes, writing in
parallel, and writing to a write-ahead-log (WAL), which is also called
journaling.

### Batching Writes

The first way involves grouping up writes into one write and writing a
big block instead of just one write. Since most of the latency involved
occurs due to the fsync, this greatly increases throughput, at the cost
of latency per write.

Imagine your disk chooses to batch every `n` writes. If so, each first
write in a batch of `n` writes now takes on average one fsync + the
amount of time it takes your system to gather up `n` writes. This
increases the amount of data that is written, at the cost of latency. As
well, a write isn't persistent until it is written to disk. Thus, there
is another choice: either the system says a write has completed before
it is safely persisted to disk, which is more responsive but not
persistent, or only say a write has completed after it is safely
persisted to disk, which is less responsive but persistent.

Your file system most likely does this by default[^3], as does your
storage device of choice, in the form of caches.

### Writing in Parallel

Another way is to write in parallel, where the system has a few disk
drives and writes to them independently. A popular taxonomy is called
RAID[^4], which involves using many drives as one atomic unit, allowing
for an increase in writes.

### Writing to a Write Ahead Log

Another way of improving performance is not to persist the write
immediately, but to use a write-ahead-log, which appends writes to a
file indicating the operations that are to be persisted to disk, before
doing the operation. By doing this, even if the computer loses power,
the computer can reconstruct its state on reboot.

### Do everything

You can also do all of the above. Since your filesystem probably caches
writes, and your OS also caches writes, and your storage device also has
a write cache, your writes are effectively batched. Your SSD also
implements writing to blocks in parallel in its firmware, so there is
some level of writing in parallel. In practice, databases backed by SSDs
can write batched rows, so sqlite can do something \~23k writes per
second on an NVMe drive, while using a WAL for durability. That's a lot
better than the \~1k writes per second an average SSD might be able to
do.

    ./sqlite-bench -batch-count 1000000 -batch-size 1 -row-size 1000 -journal-mode wal -synchronous normal ./bench.db
    Inserts:   1000000 rows
    Elapsed:   43.839s
    Rate:      22810.910 insert/sec
    File size: 1026584576 bytes

# Querying Data

Now that we know how to persist data, we need a way to read it. We could
start out with just files, but this raises a lot of questions. How do we
keep the data fast to read? How do we organize it? If we have a lot of
data, and we want to query it in complex ways, how do we keep it fast to
read?

## Relational Databases

## NoSQL Databases

## The Problems with Distributed Systems

# Indexing

## The many kinds of indexes

## The Venerable B-Tree

The B-Tree[^5] is the most common index.

## The Hash Index

## Spatial Indexes

## Inverted Indexes

# Serializing Data

## Text Encodings (like JSON)

## Binary Encodings (like Protobuf)

# Networking

## How does the Internet work?

## How do you have a distributed system with many nodes?

## How do you

# References

[^1]: https://github.com/sirupsen/napkin-math

[^2]: https://www.percona.com/blog/fsync-performance-storage-devices/

[^3]: https://sirupsen.com/napkin/problem-10-mysql-transactions-per-second

[^4]: https://www.cs.cmu.edu/\~garth/RAIDpaper/Patterson88.pdf

[^5]: https://www.postgresql.org/docs/current/indexes-types.html#INDEXES-TYPES-BTREE
