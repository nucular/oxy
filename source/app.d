import std.stdio;

import oxy.jackinput;
import oxy.gloutput;
import oxy.buffer;

void main()
{
  auto input = new JackInput();
  auto output = new GLOutput();

  auto samplebuffer = new SampleBuffer(input.sampleRate / output.frameRate);
  input.samplebuffer = samplebuffer;
  output.samplebuffer = samplebuffer;

  while (input.running && output.running)
  {
    output.render();
  }
}
