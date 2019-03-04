/*
  サンプル1
  - ポタンを押している間だけモータが90度回転します
*/
#include "Ultrasonic.h"
#include "SoftwareSerial.h"
#define LIGHT_SENSOR A0
#define SOUND_SENSOR A1
#define ULTRASONIC 8

/* ここで，プログラム内で使う変数を宣言します */
Ultrasonic ultrasonic(ULTRASONIC);

/*
  setupは最初に1度だけ行うセンサやアクチュエータの設定
  各コネクタがINPUT（センサ）かOUTPUT（アクチュエータ）かをここで指定します
*/

void setup() {
  pinMode(LIGHT_SENSOR, INPUT);
  //pinMode(SOUND_SENSOR, INPUT);
  Serial.begin(9600);
}

/*
  loopの中に動かしたいプログラムを書きます
  loopの中の処理はずっと繰り返し行われます（delayを入れなければ1瞬で1周を終えます）
*/
void loop() {

  int lightsensor = analogRead(LIGHT_SENSOR);
  //int soundsensor = analogRead(SOUND_SENSOR);  
  
  long RangeInInches;
  long RangeInCentimeters;

  RangeInCentimeters = ultrasonic.MeasureInCentimeters(); // two measurements should keep an interval

  //値を、0〜255の範囲にマップ
  
  RangeInCentimeters = map(RangeInCentimeters, 0, 400, 0, 255); 
  //soundsensor = map(soundsensor, 0, 1023, 0, 255); 
  lightsensor = map(lightsensor, 0, 1023, 0, 255); 

/*
  if (lightsensor < 120){
    Serial.print("OFF\n");
  } else if (20 < RangeInCentimeters && RangeInCentimeters < 60){
    Serial.print("DRAW\n");
  } else if (soundsensor < 150){
    Serial.print("MOVE-SMALL\n");
  } else {
    Serial.print("MOVE-BIG\n");
  }
  delay(100);
}
*/

  if (lightsensor < 80){
    Serial.print("OFF\n");
  } else if (25 < RangeInCentimeters && RangeInCentimeters < 60){
    Serial.print("DRAW\n");
  } else {
    Serial.print("MOVE\n");
  }
  delay(100);
}

