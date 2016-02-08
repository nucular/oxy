module oxy.jackinput;

import core.thread;
import std.stdio;
import oxy.input;
import oxy.buffer;
import jack.client;
import jack.port;


class JackInput : Input
{
  JackClient client;
  JackPort inX;
  JackPort inY;

  this()
  {
    this.client = new JackClient();
    this.client.open("oxy", JackOptions.JackNoStartServer, null);

    this.inX = this.client.register_port("x_axis", "32 bit float mono audio",
      JackPortFlags.JackPortIsInput, 0);
    this.inY = this.client.register_port("y_axis", "32 bit float mono audio",
      JackPortFlags.JackPortIsInput, 0);

    this.client.process_callback = delegate int (jack_nframes_t nframes)
    {
      if (!this.samplebuffer) return 0;

      float* bufferX = this.inX.get_audio_buffer(nframes);
      float* bufferY = this.inY.get_audio_buffer(nframes);

      for (jack_nframes_t i = 0; i < nframes; i++)
        this.samplebuffer.enqueue([*(bufferY++), *(bufferX++)]);

      return 0;
    };

    this.client.activate();
    this.running = true;
  }

  ~this()
  {
    this.client.close();
  }

  @property override int sampleRate() { return this.client.get_sample_rate(); }

  @property override int bufferSize() { return this.client.get_buffer_size(); }
  @property override void bufferSize(int v) { this.client.set_buffer_size(v); }
}
