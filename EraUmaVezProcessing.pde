/**
 * This sketch demonstrates how to use the <code>position</code> method of a <code>Playable</code> class. 
 * The class used here is <code>AudioPlayer</code>, but you can also get the position of an <code>AudioSnippet</code>.
 * The position is the current position of the "playhead" in milliseconds. In other words, it's how much of the 
 * recording has been played. This sketch demonstrates how you could use the <code>position</code> method to 
 * visualize where in the recording playback is.
 *
 */

import ddf.minim.*;
import java.awt.*;

Minim minim;
AudioPlayer groove;
WaveformRenderer waveform;

float[] L, R;
int[] Lx, Ly, Rx, Ry;

final String fn = "groove.mp3";
//final String fn = "h3.mp3";

// for eps file
FileOutputStream finalImage;
EpsGraphics2D g;
boolean drawEps;


void setup() {
  size(1024, 400, P3D);
  //frameRate(700);

  L = new float[width];
  R = new float[width];

  Lx = new int[width];
  Ly = new int[width];
  Rx = new int[width];
  Ry = new int[width];

  minim = new Minim(this);
  waveform = new WaveformRenderer();

  // open file just to get its size
  groove = minim.loadFile(fn, 2048);

  println(groove.bufferSize());
  println(groove.left.toArray().length);
  println("sample rate: " + groove.sampleRate());
  println("total samples: " + groove.length()/1000.0*groove.sampleRate());
  println("samples per pixel: "+ (groove.length()/1000.0*groove.sampleRate())/width);

  try {
    finalImage = new FileOutputStream(dataPath(fn+".eps"));
    g = new EpsGraphics2D(fn, finalImage, 0, 0, width, height);

    g.setBackground(Color.BLACK);
    g.clearRect(0, 0, width, height);
    g.setColor(Color.WHITE);

    drawEps = true;
  }
  catch (Exception e) {
    println("Erro: arquivo .eps não pode ser criado");
    exit();
  }


  // reset groove to get buffers of the right size.
  //   this way each horizontal pixel on the screen reperesents one full buffer of audio.
  groove.close();
  groove = minim.loadFile(fn, int((groove.length()/1000.0*groove.sampleRate())/width));

  groove.addListener(waveform);
  groove.play();
}

void draw() {
  background(0);

  // see waveform.pde for an explanation of how this works
  waveform.draw();

  PVector p = waveform.getPoints();

  if ((int)p.x < width) {
    L[(int)p.x] = 1*(height/4) + p.y*(height/4);
    R[(int)p.x] = 3*(height/4) + p.z*(height/4);
  }
  else {
    int Lc = 0;
    int Rc = 0;

    noFill();
    stroke(255);

    beginShape();
    for (int i=0; i<width; i++) {
      if (L[i] > 0) {
        vertex(i, L[i]);

        Lx[Lc] = i;
        Ly[Lc] = (int)L[i];
        Lc++;
      }
    }
    endShape();

    beginShape();
    for (int i=0; i<width; i++) {
      if (R[i] > 0) {
        vertex(i, R[i]);

        Rx[Rc] = i;
        Ry[Rc] = (int)R[i];
        Rc++;
      }
    }
    endShape();

    if (drawEps == true) {
      // draw eps

      // left channel
      for (int i=1; i<Lc; i++) {
        g.drawLine(Lx[i-1], Ly[i-1], Lx[i], Ly[i]);
      }

      // right channel
      for (int i=1; i<Rc; i++) {
        g.drawLine(Rx[i-1], Ry[i-1], Rx[i], Ry[i]);
      }

      try {
        g.flush();
        g.close();
        finalImage.close();
      }
      catch(Exception e) {
      }

      drawEps = false;
    }
  }



  float x = map(groove.position(), 0, groove.length(), 0, width);
  stroke(255, 0, 0);
  line(x, height/2 - 30, x, height/2 + 30);
}

void stop() {
  // always close Minim audio classes when you are done with them
  groove.close();
  // always stop Minim before exiting.
  minim.stop();

  super.stop();
}

