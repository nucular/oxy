module oxy.buffer;

import core.atomic;
import core.thread;
import std.stdio;

/**
* One-producer one-consumer lockless ring buffer implementation.
**/
class OPOCRingBuffer(T)
{
  size_t capacity;

  private
  {
    size_t mask;
    shared size_t writei;
    shared size_t readi;
    T[] buffer;
  }

  this(size_t capacity)
  {
    this.buffer = new T[](capacity);
    this.capacity = capacity;
    this.mask = capacity - 1;
    this.clear();
  }

  @property const bool empty()
  {
    atomicFence();
    return this.readi == this.writei;
  }

  void clear()
  {
    atomicStore(this.readi, cast(size_t)0);
    atomicStore(this.writei, cast(size_t)0);
  }

  bool enqueue(in T item)
  {
    const auto tail = atomicLoad(this.writei);
    const auto nexttail = (tail + 1) & this.mask;
    if (nexttail != atomicLoad(this.readi))
    {
      this.buffer[tail] = item;
      atomicStore(this.writei, nexttail);
      return true;
    }
    return false;
  }

  void forceEnqueue(in T item)
  {
    while (!this.enqueue(item)) { Thread.yield(); }
  }

  bool tryEnqueue(in T item, ref int spins)
  {
    while (spins--)
    {
      if (this.enqueue(item))
        return true;
      else
        Thread.yield();
    }
    return false;
  }

  bool dequeue(out T output)
  {
    auto head = atomicLoad(this.readi);
    if (head == atomicLoad(this.writei))
    {
      return false;
    }
    output = this.buffer[head];
    atomicStore(this.readi, (head + 1) & this.mask);
    return true;
  }

  void forceDequeue(out T output)
  {
    while (!this.dequeue(output)) { Thread.yield(); }
  }

  bool tryDequeue(out T output, ref int spins)
  {
    while (spins--)
    {
      if (this.dequeue(output))
        return true;
      else
        Thread.yield();
    }
    return false;
  }
}

alias Sample = float[2];
alias SampleBuffer = OPOCRingBuffer!(Sample);
