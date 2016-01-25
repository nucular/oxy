module oxy.input;

import oxy.buffer;

abstract class Input
{
  SampleBuffer samplebuffer;
  bool running;

  @property int sampleRate();

  @property int bufferSize();
  @property void bufferSize(int);
}
