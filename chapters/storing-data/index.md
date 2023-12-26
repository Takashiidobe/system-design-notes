# Storing Data

## RAM vs Disk

Simplifying the memory of a computer, you can imagine that there are two types of memory, volatile and non-volatile. Volatile memory does not keep its state after it loses power. On the flip side, Non-volatile memory keeps its state even without power.

In a computer, volatile memory is Random Access Memory (RAM), the memory that is used by the computer as it runs programs. Non-volatile memory would be a hard drive or an SSD. For a hard drive, a plate engraves the physical bytes onto the disk, which allows it to save its state without electricity. For an SSD, electricity is used to write to transistors which keep the state of the drive in a way that allows it to survive without continuous power.

We'll call volatile memory `RAM`, and non-volatile memory `Disk`.

## Files

The way state is saved on disk is with files. Files, when saved on a disk drive, persist their data even after a shutdown. One way to use this in system design is to save every change made onto disk. This works, but is ill-performant. Saving a file in a persistent way on disk requires a special system call on unix called `fsync`. This takes ~1ms on an SSD[^1], or ~20ms on an HDD[^2]. On HDD backed computers, that means **only** 50 writes per second can be persisted, no matter how fast the CPU is. On an SSD, a slightly less abysmal 1000 writes can be saved a second. For systems that never have to handle more persistent writes, using fsyncs one after another works fine.

[^1]: https://github.com/sirupsen/napkin-math
[^2]: https://www.percona.com/blog/fsync-performance-storage-devices/

## Speeding up writes

You might wonder how planet scale companies scaled on commodity hardware that used HDDs. There are a few ways: batching writes, writing in parallel, and writing to a write-ahead-log (WAL), which is also called journaling.

### Batching Writes

The first way involves grouping up writes into one write and writing a big block instead of just one write. Since most of the latency involved occurs due to the fsync, this greatly increases throughput, at the cost of latency per write.

Imagine your disk chooses to batch every `n` writes. If so, each first write in a batch of `n` writes now takes on average one fsync + the amount of time it takes your system to gather up `n` writes. This increases the amount of data that is written, at the cost of latency. As well, a write isn't persistent until it is written to disk. Thus, there is another choice: either the system says a write has completed before it is safely persisted to disk, which is more responsive but not persistent, or only say a write has completed after it is safely persisted to disk, which is less responsive but persistent.

Your file system most likely does this by default[^3], as does your storage device of choice, in the form of caches.

[^3]: https://sirupsen.com/napkin/problem-10-mysql-transactions-per-second

### Writing in Parallel

Another way is to write in parallel, where the system has a few disk drives and writes to them independently. A popular taxonomy is called RAID[^4], which involves using many drives as one atomic unit, allowing for an increase in writes.

[^4]: https://www.cs.cmu.edu/~garth/RAIDpaper/Patterson88.pdf

### Writing to a Write Ahead Log

Another way of improving performance is not to persist the write immediately, but to use a write-ahead-log, which appends writes to a file indicating the operations that are to be persisted to disk, before doing the operation. By doing this, even if the computer loses power, the computer can reconstruct its state on reboot.

### Writing Asynchronously

Another way is to read and write asynchronously, supported by the `aio_*` unix APIs.

For some numbers, I benchmarked my own setup:

Using the synchronous unix APIs (`read`, `write`):

- synchronous sequential write - fsync: ~2.4k ops/s, (623MB/s)
- synchronous sequential write + fsync: ~850 ops/s, (222MB/s)
- synchronous random write - fsync: ~2.4k ops/s, (644MB/s)
- synchronous random write + fsync: ~800 ops/s, (214MB/s)
- synchronous sequential read: ~2.9k ops/s, (757MB/s)
- synchronous random read: ~2.2k ops/s, (575MB/s)

With `aio_*`:

- asynchronous sequential write - fsync: ~2.3k ops/s, (599MB/s)
- asynchronous sequential write + fsync: ~800 ops/s, (212MB/s)
- asynchronous random write - fsync: ~2.3k ops/s, (592MB/s)
- asynchronous random write + fsync: ~800 ops/s, (217MB/s)
- asynchronous sequential read: ~3k ops/s, (763MB/s)
- asynchronous random read: ~2.1k ops/s, (561MB/s)

The asynchronous APIs aren't that much better on Linux on my setup, only for sequential writes.

### Avoiding the OS' Page Cache

Another way of improving performance that databases use is to avoid the Operating System's Page cache. This allows for faster performance, but is tricky to implement. Databases might use this pretty frequently.

The numbers using the synchronous unix APIs (`read`, `write`) again:

- synchronous sequential write - fsync: ~2.4k ops/s, (623MB/s)
- synchronous sequential write + fsync: ~850 ops/s, (222MB/s)
- synchronous random write - fsync: ~2.4k ops/s, (644MB/s)
- synchronous random write + fsync: ~800 ops/s, (214MB/s)
- synchronous sequential read: ~2.9k ops/s, (757MB/s)
- synchronous random read: ~2.2k ops/s, (575MB/s)

Using `io_uring`, which avoids the operating system's cache:

- io_uring sequential write - fsync: ~2.8k ops/s, (723MB/s)
- io_uring sequential write + fsync: ~2.5k ops/s, (653MB/s)
- io_uring random write - fsync: ~3.3k ops/s, (872MB/s)
- io_uring random write + fsync: ~2.4k ops/s, (639MB/s)
- io_uring sequential read: ~15k ops/s, (3876MB/s)
- io_uring random read: ~7.5k ops/s, (1997MB/s)

`io_uring` offers some improvements.

### Do everything

You can also do all of the above. Since your filesystem probably caches writes, and your OS also caches writes, and your storage device also has a write cache, your writes are effectively batched. Your SSD also implements writing to blocks in parallel in its firmware, so there is some level of writing in parallel. In practice, databases backed by SSDs can write batched rows, so sqlite can do many more writes per second than 1k on an NVMe drive, while using a WAL for durability. That's a lot better than the ~1k writes per second an average SSD would be able to write using `fsync`.

Let's bring it all together: how much faster do all these optimizations make writing to disk? I benchmarked my own laptop, a 16 core 12th Gen Intel i5-1240P with a Western Digital SN750, rated at 3400 MB/s sequential read, 2900 MB/s sequential write.

On this disk, it's possible to write **23k** rows per second, so each write takes about **40 microseconds**, instead of the expected **1ms**.

```
./sqlite-bench -batch-count 1000000 -batch-size 1 -row-size 1000 -journal-mode wal -synchronous normal ./bench.db
Inserts:   1000000 rows
Elapsed:   43.839s
Rate:      22810.910 insert/sec
File size: 1026584576 bytes
```

But we can batch more. Batching at the SQL level, 1000 rows per batch, our throughput has increased to **130k** rows per second, so each row write takes only **8 microseconds**.

```
./sqlite-bench -batch-count 1000 -batch-size 1000 -row-size 1000 -journal-mode wal -synchronous normal ./bench.db
Inserts:   1000000 rows
Elapsed:   7.824s
Rate:      127817.265 insert/sec
File size: 1026584576 bytes
```

This is enough to write **11 billion rows** each carrying 4KB a day on my laptop. With just `fsync` and none of these optimizations, it'd be closer to **10 million**, or a 1000x increase. I'd have to replace my SSD once every few days to handle that kind of write bandwidth, but it goes to show how much one computer can do these days with a $250 CPU and a $100 SSD.
