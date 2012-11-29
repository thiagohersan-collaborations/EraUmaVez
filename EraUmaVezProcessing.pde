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

ArrayList<PVector> envelopeMinR, envelopeMinL, envelopeMaxR, envelopeMaxL;

final String fn = "groove.mp3";
//final String fn = "h3.mp3";

// for eps file
FileOutputStream finalImage;
EpsGraphics2D g;
boolean drawEps;


void setup() {
  size(1024, 400);
  //frameRate(700);

  L = new float[width];
  R = new float[width];

  Lx = new int[width];
  Ly = new int[width];
  Rx = new int[width];
  Ry = new int[width];

  envelopeMinL = new ArrayList<PVector>();
  envelopeMinR = new ArrayList<PVector>();
  envelopeMaxL = new ArrayList<PVector>();
  envelopeMaxR = new ArrayList<PVector>();


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

  background(0);
  smooth();
}

void draw() {

  // see waveform.pde for an explanation of how this works
  waveform.draw();

  PVector p = waveform.getPoints();

  if ((int)p.x < width) {
    L[(int)p.x] = 1*(height/4) + p.y*(height/4);
    R[(int)p.x] = 3*(height/4) + p.z*(height/4);

    background(0);
    float x = map(groove.position(), 0, groove.length(), 0, width);
    stroke(255, 0, 0);
    line(x, height/2 - 30, x, height/2 + 30);
  }
  else if (drawEps == true) {
    background(0);

    boolean goingUpL, goingUpR; 
    PVector oldL, oldR;
    goingUpL = goingUpR = false;
    oldL = new PVector(-1, -1);
    oldR = new PVector(-1, -1);


    int Lc = 0;
    int Rc = 0;

    noFill();
    stroke(255);

    beginShape();
    for (int i=0; i<width; i++) {
      if (L[i] > 0) {
        vertex(i, L[i]);

        if ((L[i] <= oldL.y) && (goingUpL == true)) {
          PVector pv = new PVector(oldL.x, oldL.y);
          envelopeMinL.add(pv);
        }
        else if ((L[i] > oldL.y) && (oldL.y > -1) && (goingUpL == false)) {
          PVector pv = new PVector(oldL.x, oldL.y);
          envelopeMaxL.add(pv);
        }
        goingUpL = (L[i] > oldL.y);

        Lx[Lc] = i;
        Ly[Lc] = (int)L[i];
        oldL.y = (int)L[i];
        oldL.x = i;

        Lc++;
      }
    }
    endShape();

    beginShape();
    for (int i=0; i<width; i++) {
      if (R[i] > 0) {
        vertex(i, R[i]);

        if ((R[i] <= oldR.y) && (goingUpR == true)) {
          PVector pv = new PVector(oldR.x, oldR.y);
          envelopeMinR.add(pv);
        }
        else if ((R[i] > oldR.y) && (oldR.y > -1) && (goingUpR == false)) {
          PVector pv = new PVector(oldR.x, oldR.y);
          envelopeMaxR.add(pv);
        }
        goingUpR = (R[i] > oldR.y);

        Rx[Rc] = i;
        Ry[Rc] = (int)R[i];
        oldR.y = (int)R[i];
        oldR.x = i;

        Rc++;
      }
    }
    endShape();

    // eps
    // left channel
    for (int i=1; i<Lc; i++) {
      //g.drawLine(Lx[i-1], Ly[i-1], Lx[i], Ly[i]);
    }
    // right channel
    for (int i=1; i<Rc; i++) {
      //g.drawLine(Rx[i-1], Ry[i-1], Rx[i], Ry[i]);
    }

    // envelope
    println(envelopeMinL.size()+"   "+envelopeMinR.size());
    println(envelopeMaxL.size()+"   "+envelopeMaxR.size());

    fill(255, 0, 0);
    stroke(255, 0, 0);
    for (int i=1; i<envelopeMinL.size(); i++) {
      PVector pv0 = envelopeMinL.get(i-1);
      PVector pv1 = envelopeMinL.get(i);
      ellipse(pv0.x, pv0.y, 2, 2);
      bezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2, (pv0.y), (pv0.x+pv1.x)/2, (pv1.y), pv1.x, pv1.y);

      // eps
      g.drawBezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2f, (pv0.y), (pv0.x+pv1.x)/2f, (pv1.y), pv1.x, pv1.y);
    }
    for (int i=1; i<envelopeMinR.size(); i++) {
      PVector pv0 = envelopeMinR.get(i-1);
      PVector pv1 = envelopeMinR.get(i);
      ellipse(pv0.x, pv0.y, 2, 2);
      bezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2, (pv0.y), (pv0.x+pv1.x)/2, (pv1.y), pv1.x, pv1.y);

      // eps
      g.drawBezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2, (pv0.y), (pv0.x+pv1.x)/2, (pv1.y), pv1.x, pv1.y);
    }

    fill(0, 0, 255);
    stroke(0, 0, 255);
    for (int i=1; i<envelopeMaxL.size(); i++) {
      PVector pv0 = envelopeMaxL.get(i-1);
      PVector pv1 = envelopeMaxL.get(i);
      ellipse(pv0.x, pv0.y, 2, 2);
      bezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2, (pv0.y), (pv0.x+pv1.x)/2, (pv1.y), pv1.x, pv1.y);

      //eps
      g.drawBezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2, (pv0.y), (pv0.x+pv1.x)/2, (pv1.y), pv1.x, pv1.y);
    }
    for (int i=1; i<envelopeMaxR.size(); i++) {
      PVector pv0 = envelopeMaxR.get(i-1);
      PVector pv1 = envelopeMaxR.get(i);
      ellipse(pv0.x, pv0.y, 2, 2);
      bezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2, (pv0.y), (pv0.x+pv1.x)/2, (pv1.y), pv1.x, pv1.y);

      //eps
      g.drawBezier(pv0.x, pv0.y, (pv0.x+pv1.x)/2, (pv0.y), (pv0.x+pv1.x)/2, (pv1.y), pv1.x, pv1.y);
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

void stop() {
  // always close Minim audio classes when you are done with them
  groove.close();
  // always stop Minim before exiting.
  minim.stop();

  super.stop();
}

