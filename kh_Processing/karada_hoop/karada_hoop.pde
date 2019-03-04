

// ****************************** 変数定義 ****************************** //


//各自の環境に合わせて書き換えること
String csvPath = "C:\\Users\\InteractionDesign04\\UbuntuHome\\kh_Python\\healthplanet\\000.00.csv"; //本番用
//String csvPath = "C:\\Users\\InteractionDesign04\\Document\\data.csv"; //csvファイルの絶対パス（30データテスト用）
//String csvPath = "C:\\Users\\InteractionDesign04\\Desktop\\karada_hoop\\data\\test05.csv"; //撮影用30データ

//調整用変数
float standard_Rad = 220; //直径の基準値
int center_percent = 80; //中心のパーセンテージ(％)
int opacity_step = 5; //過去データ描画時の不透明度の減少量
int set_move_step = 50; //増減の変化頻度（0が最頻）
float move_speed = 0.001; //moveの1ステップあたりの移動量
int set_past_time = 20000; //過去データの描画にかける時間（ミリ秒）

//調整用変数（テスト用）
int setcolor = 0; // ON:1  OFF:0
int colorselect = 0; //2,1,0,-1,-2から選択（とても良い 2 ～ とても悪い -2）

//時間管理用変数
int millis; //プログラム開始からの時間（ミリ秒）
int millis_before_distance; //距離センサ用（ミリ秒）
int millis_fadeout; //フェードアウト用（ミリ秒）
int millis_past; //過去データ描画用（ミリ秒）
int millis_latest;
int millis_end_draw; //最新データの描画終了時刻（ミリ秒）

//ソケット通信用変数
import processing.net.*;
int port = 10001; //Pythonとの通信用ポート番号
Server server; //サーバ構築用変数

//座標用変数
float[] x; //各パラメータの座標を決めるために使う（x）
float[] y; //各パラメータの座標を決めるために使う（y）
int shapeRes = 7; //7角形を書く
float angle; //各パラメータの座標を決めるために使う（角度）

//csvファイル用変数
Table csvData; //csvファイルに書かれたパラメータを格納する変数
int RowMax; //データ数
float[][] Rad_memory; //直径記憶用

//move()用変数
float[][] move_magnification; //move()で用いる、直径拡大率を保存する変数
int[][] select; //move()で用いる、増減選択を記憶する変数
int move_step; //move()で用いるステップ変数

//fadeout()用変数
int fadeout_step; //fadeout()で用いるステップ変数

//draw_past_circle()用変数
int past_step; //draw_past_circle()で用いるステップ変数

//drawCC()用変数
int cC = 70; //同心円の数
float[][] cCX; //同心円のX座標［何番目の円の］［何番目の頂点］
float[][] cCY; //同心円のY座標［何番目の円の］［何番目の頂点］
float[] cCRadius; //同心円の直径
float cCGap = 3; //同心円の間隔
int cCAlpha = 0;

//体調を決定（値が大きいほど良い）
int before_condition;
int condition;


//フラグ
int done_flg;

//MODEで用いる変数
int MODE;
int NEXT_MODE;
public static final int M_OFF = 0;
public static final int M_FADEOUT = 1;
public static final int M_UPDATE = 2;
public static final int M_PAST = 3;
public static final int M_WAIT = 4;
public static final int M_LOAD = 5;
public static final int M_LATEST = 6;
public static final int M_VIEW = 7;
public static final int M_MOVE = 8;


// ****************************** 重要関数 ****************************** //


//起動時に行われる動作を設定
void setup() {
  frameRate(30);
  fullScreen();
  background(0); //背景色
  smooth(); //スムージング
  pixelDensity(displayDensity()); //retinaディスプレイ用

  //変数の初期化
  //コンディション変数
  before_condition = 0;
  condition = 0;

  //時間管理変数
  millis_fadeout = 0;
  millis_past = 0;
  millis_latest = 0;
  millis_end_draw = 0;
  millis_before_distance = 0;

  //その他の変数
  MODE = M_MOVE;
  NEXT_MODE = -1;
  fadeout_step = 0;
  past_step = 0;
  done_flg = 0;

  server = new Server(this, port); //Pythonとの通信用サーバを構築

  angle = TWO_PI/shapeRes; //何度間隔で頂点を打つか（ラジアン）
  x = new float[shapeRes];
  y = new float[shapeRes];
  
  //Rad_memoryの初期化
  Rad_memory = new float[30][shapeRes];
  for ( int RowNum = 0; RowNum < 30; RowNum++ ){
    for ( int i = 0; i <shapeRes; i++ ){
      Rad_memory[RowNum][i] = 0.0;
    }
  }
  
  set_parameter();

}


//起動後にループして行われる動作を設定
void draw() {
  millis = millis();
  sensor();      //センサ情報を受け取る（Python経由）
  mode();        //次のモードを決定する
  execution();   //モードに従い処理を行う
}


//センサ情報を受け取る
void sensor() {
  Client client = server.available();
  if (client != null) {
    String whatClientSaid = client.readString();
    if (whatClientSaid != null) {
      switch(whatClientSaid) {
      case "OFF" :
        MODE = M_OFF;
        break;
      case "DRAW" :
        MODE = M_FADEOUT;
        break;
      case "DONE":
        done_flg = 1;
        break;
      case "MOVE" :
        MODE = M_MOVE;
        break;
      }
    }
  }
}


//モードを決定する
void mode() {

  if ( NEXT_MODE != -1 ) {
    if ( NEXT_MODE == M_WAIT && done_flg == 1 ) {
      done_flg = 0;
      MODE = M_LOAD;
    } else {
      MODE = NEXT_MODE;
      //M_FADEOUT -> M_UPDATE
      //M_UPDATE -> M_PAST
      //M_PAST -> M_WAIT
      //M_LOAD -> M_LATEST
    }
  } else if ( millis - millis_end_draw < 10000 && 10000 < millis ) {
    MODE = M_VIEW;
  }
}


//モードに従い処理を行う
void execution() {
  switch(MODE) {
  case M_OFF:
    background(0);
    break;
  case M_FADEOUT:
    fadeout();
    break;
  case M_UPDATE:
    update();
    break;
  case M_PAST:
    draw_past_circle();
    break;
  case M_WAIT:
    break;
  case M_LOAD:
    load_latest();
    break;
  case M_LATEST:
    background(0);
    draw_past_circle_2();
    drawCCAlpha();
    break;
  case M_VIEW:
    break;
  case M_MOVE:
    background(0);
    move(0);
    break;
  }
}


// ****************************** 各モードで使用する関数 ****************************** //


//フェードアウトさせる（約5秒）
void fadeout() {
  background(0);
  if (millis - millis_fadeout > 50) {
    fadeout_step++;
    millis_fadeout = millis;
  }

  move(fadeout_step);

  //終了判定
  if (fadeout_step == 100) {
    fadeout_step = 0;
    background(0);
    NEXT_MODE = M_UPDATE;
  } else {
    NEXT_MODE = M_FADEOUT;
  }
}


//30データある場合は基準値を変更して再計算
void update() {
  if (RowMax == 30) {
    csvData.removeRow(0);
    RowMax = RowMax - 1;
    calc_Rad();
  }
  NEXT_MODE = M_PAST;
}


//過去データを順に描画する（約set_past_timeミリ秒）
void draw_past_circle() {
  float calc[];
  int opacity;
  int stepin_interval = set_past_time / RowMax;

  //一定のインターバルで過去データを描画する
  if (millis - millis_past > stepin_interval) {
    for (int i = 0; i < shapeRes; i++) {
      calc = calc_plot(past_step, i, 1.00);
      x[i] = calc[0];
      y[i] = calc[1];
    }

    opacity = calc_opacity(past_step, MODE);

    draw_circle(opacity); //円を描画する

    past_step++;
    millis_past = millis;
  }

  //終了判定
  if (past_step == RowMax) {
    past_step = 0;
    NEXT_MODE = M_WAIT;
  } else {
    NEXT_MODE = M_PAST;
  }
}


//最新データを取得する
void load_latest() {
  set_parameter();
  NEXT_MODE = M_LATEST;
}


//過去データを一度に描画する
void draw_past_circle_2() {
  float calc[];
  int opacity;
  int RowMax = csvData.getRowCount();
  for (int RowNum = 0; RowNum < RowMax; RowNum++) {
    for (int i = 0; i < shapeRes; i++) {
      //座標の計算
      calc = calc_plot(RowNum, i, 1.00);
      x[i] = calc[0];
      y[i] = calc[1];
    }

    opacity = calc_opacity(RowNum, MODE);

    draw_circle(opacity); //円を描画する
  }
}


//最新データを描画する
void drawCCAlpha() {
  if ( millis - millis_latest > 5 ) {
    millis_latest = millis();
    cCAlpha = cCAlpha + 2;
    if (cCAlpha > 100) { //不透明度が100以上であれば100で描画
      cCAlpha = 100;
    }
    drawCC(cCAlpha); //描画

    //終了判定
    if (cCAlpha == 100) {
      cCAlpha = 0;
      NEXT_MODE = -1;
      millis_end_draw = millis();
    }
  }
}


//最新データの描画用関数
void drawCC(int cCAlpha) {
  translate(width /2, height /2); //画面中心を原点に
  noFill(); //塗りなし
  smooth(); //スムージング
  float color_RGB[];
  float weight; //線幅

  for (int j = 0; j < cC; j++) { //同心円の数でループ回す

    weight = map(j, cC, 0, 0, 2); //一番内側の同心円を1px, 一番外側の同心円を0px
    strokeWeight(weight);

    color_RGB = calc_color(j); //色の計算
    stroke(color_RGB[0], color_RGB[1], color_RGB[2], cCAlpha);

    //実際に円を描く
    beginShape();
    curveVertex(cCX[j][shapeRes-1], cCY[j][shapeRes-1]);
    for (int k = 0; k < shapeRes; k++) {
      curveVertex(cCX[j][k], cCY[j][k]);
    }
    curveVertex(cCX[j][0], cCY[j][0]); 
    curveVertex(cCX[j][1], cCY[j][1]);
    endShape();
  }
}


//円の描画
void draw_circle(int opacity) {
  translate(width /2, height /2);
  fill(255, 0); //塗りの色（色, 透明度)
  stroke(0, 255, 0, opacity); //線の色（R,G,B,不透明度）

  //実際に円を描く
  beginShape();
  strokeWeight(1.35);
  curveVertex(x[shapeRes-1], y[shapeRes-1]);
  for (int i = 0; i < shapeRes; i++) {
    curveVertex(x[i], y[i]);
  }
  curveVertex(x[0], y[0]); 
  curveVertex(x[1], y[1]);
  endShape();
  translate(-width /2, -height /2);
}


//待機状態
void move(int fadeout_step) {
  float calc[];
  int opacity;

  //過去データ
  for (int RowNum = 0; RowNum < RowMax -1; RowNum++) {

    //倍率の変更
    calc_magnification(RowNum);

    //座標の計算
    for (int i = 0; i < shapeRes; i++) {
      calc = calc_plot(RowNum, i, move_magnification[RowNum][i]);
      x[i] = calc[0];
      y[i] = calc[1];
    }

    opacity = calc_opacity(RowNum, MODE);

    draw_circle(opacity);
  }

  //最新データ
  calc_magnification(RowMax-1);
  calc_cC();
  drawCC(100 - fadeout_step);

  //ステップの更新
  move_step++;
  if (move_step > set_move_step) {
    move_step = 0;
  }
}


//パラメータの初期化
void set_parameter() {
  csvData = loadTable(csvPath, "header");
  RowMax = csvData.getRowCount();
  if ( RowMax > 30 ) {
    for (int i = 0; i < RowMax - 30; i++) {
      csvData.removeRow(0);
    }
    RowMax = csvData.getRowCount();
  }
  //move_magnificationの初期化
  move_magnification = new float[RowMax][shapeRes];
  for (int RowNum = 0; RowNum < RowMax; RowNum++) {
    for (int i = 0; i < shapeRes; i++) {
      move_magnification[RowNum][i] = 1.00;
    }
  }
  select = new int[RowMax][shapeRes];
  calc_Rad();
  calc_condition();
  calc_cC();
}


// ****************************** 計算用関数 ****************************** //


//直径の計算
void calc_Rad() {
  if (MODE == M_LOAD) {
    calc_Rad_2(RowMax-1);
  } else {
    for (int RowNum = 0; RowNum < RowMax; RowNum++) {
      calc_Rad_2(RowNum);
    }
  }
}


//直径の計算2
void calc_Rad_2(int RowNum) {
  int StatusNum_2 = 0;
  float difference;
  float Rad;

  for (int StatusNum_1 = 0; StatusNum_1 < shapeRes; StatusNum_1++) {

    //参照先の計算（csvデータがずれているため）
    switch(StatusNum_1) {
    case 0:
    case 1:
    case 2:
      StatusNum_2 = StatusNum_1 + 2;
      break;
    case 3:
      StatusNum_2 = StatusNum_1 + 3;
      break;
    case 4:
    case 5:
    case 6:
      StatusNum_2 = StatusNum_1 + 4;
      break;
    }

    difference = csvData.getFloat(RowNum, StatusNum_2) - csvData.getFloat(0, StatusNum_2);
    Rad = standard_Rad * ( 1 + ( difference / (csvData.getFloat(0, StatusNum_2) * ( 1 - center_percent/100.0 ))));
    Rad_memory[RowNum][StatusNum_1] = Rad;
  }
}


//座標の計算
float[] calc_plot(int RowNum, int StatusNum_1, float magnification) {
  float result[] = new float[2];
  float Rad;

  Rad = Rad_memory[RowNum][StatusNum_1] * magnification;

  //結果が範囲を超えないように
  Rad = max(10, Rad);
  Rad = min(Rad, standard_Rad*2);

  result[0] = cos(angle*StatusNum_1) * Rad;
  result[1] = sin(angle*StatusNum_1) * Rad;

  return result;
}


//同心円の座標計算
void calc_cC() {
  float Rad;
  //drawCC初期化
  cCX = new float[cC][shapeRes];
  cCY = new float[cC][shapeRes];

  //同心円の座標を計算, 今は外側に広がるようにしている
  for (int j = 0; j < cC; j++) {
    for (int i = 0; i < shapeRes; i++) {
      Rad = Rad_memory[RowMax-1][i] * move_magnification[RowMax-1][i];
      Rad = max(10, Rad);
      Rad = min(Rad, standard_Rad*2);
      cCX[j][i] = cos(angle *i) * (Rad + cCGap *j);
      cCY[j][i] = sin(angle *i) * (Rad + cCGap *j);
    }
  }
}


//不透明度の計算（過去になるほど薄くなる）
int calc_opacity(int RowNum, int MODE) {
  int opacity;
  opacity = 100 -  opacity_step * (RowMax-1 - RowNum);

  if (MODE == M_FADEOUT) {
    opacity = opacity - fadeout_step;
    opacity = max(0, opacity);
  } else {
    opacity = max(20, opacity);
  }

  return opacity;
}


//倍率の計算
void calc_magnification(int RowNum) {
  for (int i = 0; i < shapeRes; i++) {
    if (move_step == 0) {
      //増減の変更可 
      if (random(0, 1) > 0.5) {
        move_magnification[RowNum][i] += move_speed;
        move_magnification[RowNum][i] = min(move_magnification[RowNum][i], 1.3);
        select[RowNum][i] = 1;
      } else {
        move_magnification[RowNum][i] -= move_speed;
        move_magnification[RowNum][i] = max(move_magnification[RowNum][i], 0.7);
        select[RowNum][i] = -1;
      }
    } else {
      //増減の変更不可
      if (select[RowNum][i] == 1) {
        move_magnification[RowNum][i] += move_speed;
        move_magnification[RowNum][i] = min(move_magnification[RowNum][i], 1.3);
      } else {
        move_magnification[RowNum][i] -= move_speed;
        move_magnification[RowNum][i] = max(move_magnification[RowNum][i], 0.7);
      }
    }
  }
}


//体調の計算
void calc_condition() {
  int decision_1;
  int decision_2;
  int decision_3;

  //コンディションの更新
  before_condition = condition;

  //体重
  if (Rad_memory[RowMax-2][0] < Rad_memory[RowMax-1][0]) {
    decision_1 = -1;
  } else {
    decision_1 = 1;
  }

  //体脂肪率
  if (Rad_memory[RowMax-2][1] < Rad_memory[RowMax-1][1]) {
    decision_2 = -1;
  } else {
    decision_2 = 1;
  }

  //基礎代謝
  if (Rad_memory[RowMax-2][4] > Rad_memory[RowMax-1][4]) {
    decision_3 = -1;
  } else {
    decision_3 = 1;
  }

  //総評
  if (decision_1 + decision_2 + decision_3 <= -1) {
    condition = -1;
  } else {
    condition = 1;
  }

  //テスト用
  if (setcolor == 1) {
    switch(colorselect) {
    case 2:
      before_condition = 1;
      condition = 1;
      break;
    case 1:
      before_condition = -1;
      condition = 1;
      break;
    case 0:
      before_condition = 0;
      break;
    case -1:
      before_condition = 1;
      condition = -1;
      break;
    case -2:
      before_condition = -1;
      condition = -1;
      break;
    }
  }
}


//色の計算
float[] calc_color(int j) {
  float color_RGB[] = new float[3];

  //とても良い
  if (before_condition == 1 && condition == 1) {
    color_RGB[0] = map(j, 0, cC, 0, 0); //外に行くほどシアンを薄く
    color_RGB[1] = map(j, 0, cC, 255, 0); //外に行くほどシアンを薄く
    color_RGB[2] = map(j, 0, cC, 255, 255); //外に行くほどシアンを薄く
  }

  //良い
  else if (before_condition == -1 && condition == 1) {
    color_RGB[0] = map(j, 0, cC, 255, 0); //外に行くほどシアンに
    color_RGB[1] = map(j, 0, cC, 255, 255); //外に行くほどシアンに
    color_RGB[2] = map(j, 0, cC, 30, 255); //外に行くほどシアンに
  }

  //普通
  else if (before_condition == 0) {
    color_RGB[0] = map(j, 0, cC, 255, 255); //外に行くほど黄色に
    color_RGB[1] = map(j, 0, cC, 255, 85); //外に行くほど黄色に
    color_RGB[2] = map(j, 0, cC, 30, 165); //外に行くほど黄色に
  }

  //悪い
  else if (before_condition == 1 && condition == -1) {
    color_RGB[0] = map(j, 0, cC, 255, 255); //外に行くほどピンクに
    color_RGB[1] = map(j, 0, cC, 155, 85); //外に行くほどピンクに
    color_RGB[2] = map(j, 0, cC, 65, 165); //外に行くほどピンクに
  }

  //とても悪い
  else if (before_condition == -1 && condition == -1) {
    color_RGB[0] = map(j, 0, cC, 255, 255); //外に行くほどオレンジに
    color_RGB[1] = map(j, 0, cC, 0, 155); //外に行くほどオレンジに
    color_RGB[2] = map(j, 0, cC, 0, 65); //外に行くほどオレンジに
  }

  return color_RGB;
}
