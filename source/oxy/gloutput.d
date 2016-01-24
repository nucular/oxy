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
  GLFWwindow* window;
  double lastTime;

  Sample lastSample;

  this()
  {
    DerelictGL.load();
    DerelictGLFW3.load();

    if (!glfwInit())
      throw new Exception("glfwInit failed");

    this.window = glfwCreateWindow(800, 800, "oxy", null, null);
    if (!window)
      throw new Exception("glfwCreateWindow failed");

    glfwMakeContextCurrent(window);
    DerelictGL.reload(GLVersion.None, GLVersion.GL41);
    glfwSwapInterval(1);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glLineWidth(2.0);
    glPointSize(2.0);

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
    glBegin(GL_LINE_STRIP);

    void drawSample(Sample sample)
    {
      float sdist = pow(sample[0] - this.lastSample[0], 2) + pow(sample[1] - this.lastSample[1], 2);
      glColor4f(1.0, 1.0, 1.0, (1.0 - (sdist / 0.004)) * 1.0);
      glVertex3f(sample[0], sample[1], 0.0);
      this.lastSample = sample;
    }

    glVertex3f(this.lastSample[0], this.lastSample[1], 0.0);
    Sample sample;
    while (this.samplebuffer.tryGet(sample))
      drawSample(sample);

    glEnd();

    glfwSwapBuffers(this.window);
    glfwPollEvents();

    this.running = glfwWindowShouldClose(this.window) == 0;
  }

  @property override uint frameRate()
  {
    return 60;
  }
}
