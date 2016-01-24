module oxy.output;

import oxy.buffer;

abstract class Output
{
  SampleBuffer samplebuffer;
  bool running;

  @property uint frameRate();
}
