module oxy.buffer;

import core.atomic;

/**
  One-producer one-consumer lockless ring buffer implementation.
**/
class OPOCRingBuffer(T)
{
  size_t capacity;

  private
  {
    size_t mask;
    shared size_t writei;
    size_t readi;
    T[] buffer;
  }

  this(size_t capacity)
  {
    this.buffer = new T[](capacity);
    this.capacity = capacity;
    this.mask = capacity - 1;
    this.writei = 0;
    this.readi = 0;
  }

  @property const bool empty()
  {
    atomicFence();
    return this.readi == this.writei;
  }

  void clear()
  {
    this.readi = 0;
    atomicFence();
    this.writei = 0;
  }

  void put(in T item)
  {
    this.buffer[this.writei & this.mask] = item;
    atomicFence();
    atomicOp!"+="(this.writei, 1);
  }

  bool tryGet(out T output)
  {
    if (this.empty)
      return false;
    output = this.buffer[this.readi++ & this.mask];
    return true;
  }

  T* tryPeek()
  {
    if (this.empty)
      return null;
    return &this.buffer[this.readi];
  }

  void pop()
  {
    ++this.readi;
  }

}

alias Sample = float[2];
alias SampleBuffer = OPOCRingBuffer!(Sample);
