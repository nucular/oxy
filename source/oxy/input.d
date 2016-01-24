module oxy.input;

import oxy.buffer;

abstract class Input
{
  SampleBuffer samplebuffer;
  bool running;

  @property uint sampleRate();
}
