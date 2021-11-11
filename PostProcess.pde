import controlP5.*; //<>// //<>// //<>// //<>// //<>//
import processing.opengl.*;
import com.jogamp.opengl.GL2ES2;
import com.jogamp.opengl.util.GLBuffers;
import java.nio.FloatBuffer;

ControlP5 slider1, slider2,slider3;
float sliderValue;

//Bloom
PImage src;
float thr;

//CA
float range;
PImage CImg, CImg1, CImg2;

//DoF
GL2ES2 gl;
FloatBuffer zbuff;

float aspect, fovy, cameraZ, zNear, zFar;
PImage tex, zTex, gTex1, gTex2;
Boolean showFlag;
float focusDist, threshold;


//util

float[][]  gaussianFilter;
int w = 15;
int hw = int(w/2);

float t;

vec3[] r;

int NUM = 1000;
float[] x = new float[NUM];
float[] y = new float[NUM];
float[] z = new float[NUM];
float[] rot = new float[NUM];
float[] rSpeed = new float[NUM];
color[] col = new color[NUM];

int scene;

ArrayList<Ball> ballArray, delList;

void setup() {
  size(1500, 600, P3D);
  ballArray = new ArrayList<Ball>();
  delList = new ArrayList<Ball>();
  surface.setResizable(true);
  scene = 0;
  gaussianFilter = gaussian(10);
  setupBloom();
  setupCA();
  slider3.setVisible(false);
}

void draw() {
  if (scene == 0) drawBloom();
  else if (scene == 1) drawDoF();
  else drawCA();
}


//Bloom

void setupBloom() {
  
  frameRate(1);
  colorMode(HSB);

  t=0;
  
  //rectの設定
  r = new vec3[5];
  for (int i=0; i<5; i++) {
    r[i] = new vec3(100*i, 110*i, 0);
  }

  //mini boxesの設定
  for (int i=0; i<NUM; i++) {
    x[i] = random(width);
    y[i] = random(height);
    z[i] = random(-5000, 0);
    rot[i] = 0;
    rSpeed[i] = random(-0.1, 0.1);
    col[i] = color(random(120, 240), random(80, 100), 100);
  }

  //左画面を画像で取得
  src = get(0, 0, 500, 500);
  
  colorMode(RGB);
  /*スライダの設定*/
  PFont font = createFont("MS Gothic", 36, true);//文字の作成
  textFont (font);
  textSize(36);
  slider1 = new ControlP5(this);
  slider1.addSlider("thr")
    .setLabel("threshold")
    .setRange(0.0, 255.0)//0~255の間
    .setValue(200)//初期値
    .setPosition(width/3 + src.width/7, height-50)//位置
    .setSize(400, 24)//スライダの大きさ
    .setColorActive(color(255, 0, 0))//スライダの色
    .setColorBackground(color(255, 0, 0, 120)) //スライダの背景色 
    .setColorCaptionLabel(color(0)) //キャプションラベルの色
    .setColorForeground(color(255, 0, 0)) //スライダの色(マウスを離したとき)
    .setColorValueLabel(color(0)) //数値の色
    .setSliderMode(Slider.FIX)//スライダーの形
    .setNumberOfTickMarks(101);//メモリの値

  //スライダーの現在値
  slider1.getController("thr")
    .getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE);//位置

  colorMode(HSB);
}

void drawBloom() {
  background(0);

  colorMode(HSB);
  lights();
  
  //中央の球
  pushMatrix();
  stroke(0, 0, 255);
  fill(t*10, 200, 255);
  translate(250, 300, 0);
  rotateY(t);
  sphere(100);
  popMatrix();

  //rect
  for (int i=0; i<5; i++) {
    push();
    pushMatrix();
    noStroke();
    emissive(70*i, 240, 1000);
    fill(50*i, 240, 1000);
    rotateY(PI/2);
    rect(r[i].x+=100, r[i].y, 500, 100);
    if (r[i].x>=1100)r[i].x =-500;
    popMatrix();
    pop();
  }
  
  //mini boxes
  for (int i=0; i<NUM; i++) {
    fill(color(col[i]));
    emissive(color(col[i]));
    pushMatrix();
    translate(x[i], y[i], z[i]);
    rotateX(rot[i]);
    rotateY(rot[i]);
    rotateZ(rot[i]);
    box(15);
    popMatrix();
    z[i]+=20;
    rot[i] += rSpeed[i];
    if (z[i]>1000) {
      z[i] -= 5000;
    }
  }

  //マウスsphere
  playBall();

  t+=1;

  /*ポストプロセス*/
  src = get(0, 0, 500, 500);
  noLights();
  background(0);
  image(src, 0, 0);
  PImage bimg = overGausFil(extractBrightness(src, thr), 10);
  image(bimg, src.width, 0);
  image(Bloom(src, bimg, thr), src.width*2, 0);
}


/*Bloomとして加算する画像を作成するメソッド*/
PImage extractBrightness(PImage img, float threshold) {
  PImage exImg = createImage(img.width, img.height, HSB);
  img.loadPixels();
  exImg.loadPixels();

  float softThr = .5;
  float knee = softThr * threshold;

  for (int j = 0; j < img.height; j++) {
    for (int i = 0; i < img.width; i++) {
      int p = img.width* j + i;
      float soft = pow(min(knee * 2.0, max(0.0, brightness(img.pixels[p]) - threshold + knee)/255.0), 2);
      float b = 255.0 * (max((brightness(img.pixels[p])- threshold), soft)/max(brightness(img.pixels[p]), 0.0001));
      exImg.pixels[p] = color(hue(img.pixels[p]), saturation(img.pixels[p]), b);
    }
  }
  return exImg;
}

/*Bloomをかける関数*/
PImage Bloom(PImage img, PImage BImg, float threshold) {
  PImage bloomImg = img.copy();
  colorMode(RGB);
  bloomImg.loadPixels();
  for (int j = 0; j < img.height; j++) {
    for (int i = 0; i < img.width; i++) {
      int p = img.width * j + i;
      bloomImg.pixels[p] = color(red(bloomImg.pixels[p])+red(BImg.pixels[p]), green(bloomImg.pixels[p])+green(BImg.pixels[p]), blue(bloomImg.pixels[p])+blue(BImg.pixels[p]));
    }
  }
  bloomImg.updatePixels();
  colorMode(HSB);
  return bloomImg;
}


//ChromaticAberration

void setupCA() {
  noFill();
  stroke(0);

  frameRate(5);

  t=0;

  /*スライダの設定*/
  colorMode(RGB);
  PFont font = createFont("MS Gothic", 36, true);//文字の作成
  textFont (font);
  textSize(36);
  slider3 = new ControlP5(this);
  slider3.addSlider("range")
    .setLabel("range")
    .setRange(-0.2, 0.2)
    .setValue(0.1)//初期値
    .setPosition(50, 50)//位置
    .setSize(300, 24)//スライダの大きさ
    .setColorActive(color(255, 0, 0))//スライダの色
    .setColorBackground(color(255, 0, 0, 120)) //スライダの背景色 
    .setColorCaptionLabel(color(255)) //キャプションラベルの色
    .setColorForeground(color(255, 0, 0)) //スライダの色(マウスを離したとき)
    .setColorValueLabel(color(255)) //数値の色
    .setSliderMode(Slider.FIX)//スライダーの形
    .setNumberOfTickMarks(101);//メモリの値

  //スライダーの現在値
  slider3.getController("range")
    .getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE);//位置
}

void drawCA() {
  background(0);

  lights();

  colorMode(RGB);
  playBall(); 

  push();
  pushMatrix(); 
  fill(255, 255, 255);
  stroke(0);
  translate(width/2, height/2, -100);  //基準点を画面中央。z軸方向には-100
  rotateX(radians(-20) + t*0.1);
  rotateY(radians(-20) + t*0.1);
  box(150);
  popMatrix();
  pop();

  t++;

  //画面の取得
  //変数rangeでズレを制御
  CImg = get();
  CImg1 = CImg.copy();
  CImg1.resize(int(CImg.width * (1 + range)), int(CImg.height * (1 + range)));
  CImg2 = CImg.copy();
  CImg2.resize(int(CImg.width * (1 - range)), int(CImg.height * (1 - range)));

  //画像を加算合成。
  background(0);
  blendMode(ADD);
  
  tint(0, 255, 0, 255);
  image(CImg, 0, 0);
  
  //拡大縮小画像が中心に表示されるように。
  tint(255, 0, 0, 255);
  image(CImg1, -(CImg1.width - CImg.width)/2, -(CImg1.height - CImg.height)/2);

  tint(0, 0, 255, 255);
  image(CImg2, (CImg.width - CImg2.width)/2, (CImg.height - CImg2.height)/2);

  blendMode(NORMAL);
  noTint();
}

//DoF

void setupDoF() {
  noStroke();
  frameRate(30);
  colorMode(RGB);

  t = 0;

  showFlag = false;
  
  //zBufferの設定
  zbuff = GLBuffers.newDirectFloatBuffer(new float[]{1f});
  
  //zBufferをグレースケールで可視化する画像
  zTex = createImage(width, height, RGB);

  //camera設定
  aspect = float(width)/float(height);
  fovy =PI/3.; 
  cameraZ =(height/2.0) / tan(degrees(fovy)*PI / 360.0);  
  zNear =  cameraZ/10.0; 
  zFar=cameraZ*10.0;
  
  //DoF設定
  focusDist = 220;
  threshold = 140;

  /*スライダの設定*/
  PFont font = createFont("MS Gothic", 36, true);//文字の作成
  textFont (font);
  textSize(36);
  slider2 = new ControlP5(this);
  slider2.addSlider("threshold")
    .setLabel("threshold")
    .setRange(0.0, 255.0)//0~255の間
    .setValue(200)//初期値
    .setPosition(width/3, height-50)//位置
    .setSize(100, 14)//スライダの大きさ
    .setColorActive(color(255, 0, 0))//スライダの色
    .setColorBackground(color(255, 0, 0, 120)) //スライダの背景色 
    .setColorCaptionLabel(color(255)) //キャプションラベルの色
    .setColorForeground(color(255, 0, 0)) //スライダの色(マウスを離したとき)
    .setColorValueLabel(color(0)) //数値の色
    .setSliderMode(Slider.FIX)//スライダーの形
    .setNumberOfTickMarks(101);//メモリの値

  slider2.addSlider("focusDist")
    .setLabel("focusDist")
    .setRange(0.0, 255.0)//0~255の間
    .setValue(200)//初期値
    .setPosition(width/3*2, height-50)//位置
    .setSize(100, 14)//スライダの大きさ
    .setColorActive(color(0, 255, 0))//スライダの色
    .setColorBackground(color(255, 0, 0, 120)) //スライダの背景色 
    .setColorCaptionLabel(color(255)) //キャプションラベルの色
    .setColorForeground(color(0, 255, 0)) //スライダの色(マウスを離したとき)
    .setColorValueLabel(color(0)) //数値の色
    .setSliderMode(Slider.FIX)//スライダーの形
    .setNumberOfTickMarks(101);//メモリの値

  //スライダーの現在値
  slider2.getController("threshold")
    .getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE);//位置
  slider2.getController("focusDist")
    .getValueLabel()
    .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE);//位置
}

void drawDoF() {
  background(0);
  lights();
  colorMode(HSB);
  
  //球の道
  pushMatrix();
  translate(width/2.0, height/2.0, -100 );
  for (int j=0; j<50; j++) {
    rotateZ(PI/50.0*j + t*0.001);
    for (int i=0; i<50; i++) {
      pushMatrix();
      translate(width/3.0, height/2.0, -100.*(i-10) );
      rotateZ(PI/10.0*i);
      fill((1000 -7*i + t*10)%255, 200, 200);
      sphere(10);
      popMatrix();
    }
  }
  popMatrix();

  //回転連続立方体
  for (int i=0; i<50; i++) {
    pushMatrix();
    translate(width/3.0, height/2.0, -100.*(i-10) );
    rotateZ(PI/10.0*i - t*0.1);
    fill((-100+10*i)%255, 230, 255);
    box(100, 100, 100 );
    popMatrix();
  }

  playBall();

  t++;
  colorMode(RGB);

  gl = ((PJOGL) beginPGL()).gl.getGL2ES2();
  endPGL();

  if (!showFlag) {  //DoFを表示しない場合
    tex = get();
    gTex1 = tex.copy();
    gl.glReadPixels( mouseX, height-mouseY, 1, 1, GL2ES2.GL_DEPTH_COMPONENT, GL2ES2.GL_FLOAT, zbuff);

    float z = 2.0 * ( zbuff.get(0) - 0.5f);
    float worldZ =  2.0f*zFar * zNear / (z*(zFar-zNear)-(zFar+zNear) );

    fill(0, 102, 153, 250);
    textSize(24);
    //background(0,100);
    text(map(worldZ, -1500, -44, 0.0, 255.0), mouseX, mouseY);
  } else {  //DoFを表示する場合
    noLights();
    background(0);
    image(createFocusTex(), 0, 0, width, height);
    //image(gTex2, 0, 0,width,height);
  }
}

/*zBufferをグレースケール画像にする関数*/
void createZTex() {
  zTex.loadPixels();
  for (int j = 0; j < zTex.height; j++) {
    for (int i = 0; i < zTex.width; i++) {
      int p = zTex.width*(zTex.height - j -1) + i;
      gl.glReadPixels( i, j, 1, 1, GL2ES2.GL_DEPTH_COMPONENT, GL2ES2.GL_FLOAT, zbuff);
      float z = 2.0 * ( zbuff.get(0) - 0.5f);
      float worldZ =  2.0f*zFar * zNear / (z*(zFar-zNear)-(zFar+zNear) );
      float col = map(worldZ, -1500, -44, 0.0, 255.0);
      if (col<0) col = 0;
      else if (col>255) {
        col = 255;
      }
      zTex.pixels[p] = color(int(col));
    }
  }
  zTex.updatePixels();

  gTex1 = overGausFil(gTex1, 3);
  gTex2 = overGausFil(gTex1, 10);
}

PImage createFocusTex() {
  PImage focusTex = createImage(zTex.width, zTex.height, RGB);
  colorMode(RGB);
  focusTex.loadPixels();
  for (int j = 0; j < zTex.height; j++) {
    for (int i = 0; i < zTex.width; i++) {
      int p = zTex.width*(zTex.height - j -1) + i;
      float focusMap = map(255-abs(red(zTex.pixels[p])-focusDist), threshold, 255.1, 0.0, 255);
      float r = 0.0, g = 0.0, b = 0.0;
      if (focusMap < 255.0/2.0) {
        float ratio = convRatio(focusMap, 0.0, 255.0/2.0);
        r = ratio * red(gTex1.pixels[p]) + (1.0 - ratio) * red(gTex2.pixels[p]);
        g = ratio * green(gTex1.pixels[p]) + (1.0 - ratio) * green(gTex2.pixels[p]);
        b = ratio * blue(gTex1.pixels[p]) + (1.0 - ratio) * blue(gTex2.pixels[p]);
      } else {
        float ratio = convRatio(focusMap, 255.0/2.0, 255.0);
        r = ratio * red(tex.pixels[p]) + (1.0 - ratio) * red(gTex1.pixels[p]);
        g = ratio * green(tex.pixels[p]) + (1.0 - ratio) * green(gTex1.pixels[p]);
        b = ratio * blue(tex.pixels[p]) + (1.0 - ratio) * blue(gTex1.pixels[p]);
      }
      focusTex.pixels[p] = color(r, g, b);
    }
  }
  focusTex.updatePixels();
  return focusTex;
}

float convRatio(float co, float start, float end) {
  if (co<start) return 0.0;
  else if (co>end) return 1.0;
  return (co - start)/(end - start);
}


//ball

class Ball {

  public vec3 pos, vel;
  private float size;
  color col;

  public Ball(vec3 pos) {
    this.pos = pos;
    vel = new vec3(0, 0, -random(100));
    size =random(100.0);
    col = color(random(255), random(255), random(255));
  }

  void drawBall() {
    push();
    pushMatrix();
    noStroke();
    fill(col);
    translate(pos.x, pos.y, pos.z);
    sphere(size);
    popMatrix();
    pop();

    updateBall();
  }

  void updateBall() {
    pos.x += vel.x;
    pos.y += vel.y;
    pos.z += vel.z;
  }
}

void playBall() {
  ArrayList<Ball> remove = new ArrayList<Ball>();
  for (Ball e : ballArray) {
    if (e.pos.z<-2000) remove.add(e);
  }

  ballArray.removeAll(remove);
  for (Ball e : ballArray) {
    e.drawBall();
  }
}

void addBall() {
  ballArray.add(new Ball(new vec3(mouseX, mouseY, 100)));
}

//util

//ガウシアンフィルタを繰り返し掛ける関数
PImage overGausFil(PImage img, int times) {
  PImage BImg = img;
  for (int i = 0; i<times; i++)
    BImg = filtering(BImg, gaussianFilter);

  return BImg;
}

//ガウシアンフィルタ。授業と同様のもの。
float[][] gaussian(float s) {
  float[][] filter = new float[w][w];
  float sum = 0;
  for (int j = -hw; j <= hw; j++)
    for (int i = -hw; i <= hw; i++)
      sum += filter[j + hw][i + hw] = exp(-(i * i + j * j) /2. / s / s);

  for (int i = 0; i < w*w; i++)
    filter[int(i/w)][i % w] /= sum;

  return filter;
}

PImage filtering(PImage img, float f[][]) {
  colorMode(RGB);
  PImage filteredImg = createImage(img.width, img.height, RGB);
  img.loadPixels();
  filteredImg.loadPixels();
  for (int j = hw; j < img.height - hw; j++) {
    for (int i = hw; i < img.width - hw; i++) {
      float sum_r = .0, sum_g = .0, sum_b = .0;
      for (int l = -hw; l <= hw; l++) {
        for (int k = -hw; k <= hw; k++) {
          int p = (j+l) * img.width + i + k;
          sum_r += f[l + hw][k + hw] * red(img.pixels[p]);
          sum_g += f[l + hw][k + hw] * green(img.pixels[p]);
          sum_b += f[l + hw][k + hw] * blue(img.pixels[p]);
        }
      }
      filteredImg.pixels[j * img.width + i] = color(sum_r, sum_g, sum_b);
    }
  }
  filteredImg.updatePixels();
  colorMode(HSB);
  return(filteredImg);
}

class vec3 {

  public float x, y, z;

  public vec3(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
}

void mousePressed() {
  addBall();
}

void keyPressed() {

  if (keyCode == SHIFT) {
    if (scene == 0) {
      surface.setSize(640, 480);
      slider1.setVisible(false);
      scene = 1;
      setupDoF();
      slider2.setVisible(true);
      slider3.setVisible(false);
    } else if (scene == 1) {
      scene = 2;
      surface.setSize(800, 500);
      slider1.setVisible(false);
      slider2.setVisible(false);
      slider3.setVisible(true);
      frameRate(5);
    }else if (scene == 2) {
      scene = 0;
      surface.setSize(1500, 600);
      slider1.setVisible(true);
      slider2.setVisible(false);
      slider3.setVisible(false);
      frameRate(1);
      colorMode(HSB);
    }
  }

  if (scene == 1) {
    if (keyCode == ENTER) {
      showFlag = !showFlag;
      if (showFlag) createZTex();
    }
  }
}
