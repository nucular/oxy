import std.stdio;

import oxy.jackinput;
import oxy.gloutput;
import oxy.buffer;

void main()
{
  auto input = new JackInput();
  auto output = new GLOutput();

  auto samplebuffer = new SampleBuffer(input.bufferSize * 2);

  output.samplesPerFrame = input.sampleRate / output.frameRate;

  input.samplebuffer = samplebuffer;
  output.samplebuffer = samplebuffer;

  writefln("%s Hz / %s fps = %s samples per frame", input.sampleRate,
    output.frameRate, output.samplesPerFrame);

  while (input.running && output.running)
  {
    output.render();
  }
}
