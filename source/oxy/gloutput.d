module oxy.gloutput;

import std.stdio;
import std.algorithm;
import std.math;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl;
import derelict.opengl3.types;
import oxy.output;
import oxy.buffer;



class GLOutput : Output
{
  uint width = 512;
  uint height = 512;

  GLFWwindow* window;
  GLuint[2] textures;
  GLuint[2] fbos;
  size_t target = 0;
  size_t prevtarget = 1;

  double lastTime;
  Sample lastSample;

  this()
  {
    DerelictGL.load();
    DerelictGLFW3.load();

    if (!glfwInit())
      throw new Exception("glfwInit failed");

    this.window = glfwCreateWindow(this.width, this.height, "oxy", null, null);
    if (!window)
      throw new Exception("glfwCreateWindow failed");
    glfwSetWindowUserPointer(this.window, cast(void*)(this));

    glfwMakeContextCurrent(this.window);
    DerelictGL.reload(GLVersion.None, GLVersion.GL41);
    glfwSwapInterval(1);

    glEnable(GL_BLEND);
    glEnable(GL_TEXTURE_2D);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glLineWidth(2.0);
    glPointSize(2.0);

    glGenTextures(2, this.textures.ptr);
    glGenFramebuffers(2, this.fbos.ptr);

    for (int i = 0; i < this.textures.length; i++)
    {
      glBindTexture(GL_TEXTURE_2D, this.textures[i]);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, this.width, this.height, 0,
        GL_RGBA, GL_UNSIGNED_BYTE, null);
      glBindTexture(GL_TEXTURE_2D, 0);

      glBindFramebuffer(GL_DRAW_FRAMEBUFFER, this.fbos[i]);
      glFramebufferTexture(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, this.textures[i], 0);
      if (glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        throw new Exception("framebuffer creation failed");
      glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    }

    glfwSetFramebufferSizeCallback(this.window, &GLOutput.framebufferSizeCallback);

    this.running = true;
  }

  ~this()
  {
    glfwDestroyWindow(this.window);
    glfwTerminate();
  }

  void render()
  {
    double time = glfwGetTime();
    if ((time - this.lastTime) < (1.0 / this.frameRate))
      return;
    this.lastTime = time;

    float ratio;
    int width, height;
    glfwGetFramebufferSize(this.window, &width, &height);
    ratio = width / cast(float)(height);
    glViewport(0, 0, width, height);

    glClear(GL_COLOR_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-ratio, ratio, -1.0, 1.0, 1.0, -1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();


    /*glBindFramebuffer(GL_DRAW_FRAMEBUFFER, this.fbos[this.target]);
    glClear(GL_COLOR_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, this.textures[this.prevtarget]);

    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0); glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(0.0, 1.0); glVertex3f(-1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 1.0); glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 0.0); glVertex3f(1.0, -1.0, 0.0);
    glEnd();

    glBindTexture(GL_TEXTURE_2D, 0);*/


    glBegin(GL_LINE_STRIP);
    void drawSample(Sample sample)
    {
      float sdist = pow(sample[0] - this.lastSample[0], 2)
        + pow(sample[1] - this.lastSample[1], 2);
      glColor4f(1.0, 1.0, 1.0, (1.0 - (sdist / 0.004)) * 1.0);
      glVertex3f(sample[0], sample[1], 0.0);
      this.lastSample = sample;
    }

    glVertex3f(this.lastSample[0], this.lastSample[1], 0.0);
    Sample sample;
    for (int i = 0; i < this.samplesPerFrame; i++) {
      this.samplebuffer.dequeue(sample);
      drawSample(sample);
    }
    glEnd();


    /*glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fbos[this.target]);
    glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
      GL_COLOR_BUFFER_BIT, GL_NEAREST);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);*/

    glfwSwapBuffers(this.window);
    glfwPollEvents();

    swap(this.target, this.prevtarget);

    this.running = glfwWindowShouldClose(this.window) == 0;
  }

  @property override int frameRate() { return 60; } // TODO


  static extern(C) nothrow void framebufferSizeCallback(GLFWwindow* window,
    int w, int h)
  {
    auto that = cast(GLOutput)(glfwGetWindowUserPointer(window));
    that.width = w;
    that.height = h;
    for (int i = 0; i < that.textures.length; i++)
    {
      glBindTexture(GL_TEXTURE_2D, that.textures[i]);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA,
        GL_UNSIGNED_BYTE, null);
      glBindTexture(GL_TEXTURE_2D, 0);
    }
  }
}
