# Storing Data

## RAM vs Disk

Simplifying the memory of a computer, you can imagine that there are two types of memory, volatile and non-volatile. Volatile memory does not keep its state after it loses power. On the flip side, Non-volatile memory keeps its state even without power.

In a computer, volatile memory is Random Access Memory (RAM), the memory that is used by the computer as it runs programs. Non-volatile memory would be a hard drive or an SSD. For a hard drive, a plate engraves the physical bytes onto the disk, which allows it to save its state without electricity. For an SSD, electricity is used to write to transistors which keep the state of the drive in a way that allows it to survive without continuous power.

We'll call volatile memory `RAM`, and non-volatile memory `Disk`.

## Files

The way state is saved on disk is with files. Files, when saved on a disk drive, persist their data even after a shutdown. One way to use this in system design is to save every change made onto disk. This works, but is ill-performant. Saving a file in a persistent way on disk requires a special system call on unix called `fsync`. This takes ~1ms on an SSD, or ~20ms on an HDD. On HDD backed computers, that means **only** 50 writes per second can be persisted, no matter how fast the CPU is. On an SSD, a slightly less abysmal 1000 writes can be saved a second. For systems that never have to handle more persistent writes, using fsyncs one after another works fine.

## Speeding up writes

You might wonder how planet scale companies scaled on commodity hardware that used HDDs. There are two main ways: batching writes, and writing in parallel.

### Batching Writes

The first way involves grouping up writes into one write and writing a big block instead of just one write. Since most of the latency involved occurs due to the fsync, this greatly increases throughput, at the cost of latency per write.

Imagine your disk chooses to batch every `n` writes. If so, each first write in a batch of `n` writes now takes on average one fsync + the amount of time it takes your system to gather up `n` writes. This increases the amount of data that is written, at the cost of latency. As well, a write isn't persistent until it is written to disk. Thus, there is another choice: either the system says a write has completed before it is safely persisted to disk, which is more responsive but not persistent, or only say a write has completed after it is safely persisted to disk, which is less responsive but persistent.

Your file system most likely does this by default, as does your storage device of choice, in the form of caches.

### Writing in Parallel

Another way is to write in parallel, where the system has a few disk drives and writes to them independently. A popular taxonomy is called RAID, which involves using many drives as one atomic unit, allowing for an increase in writes.

### Use both

You can, of course, do both.
