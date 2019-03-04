# -*- coding: utf-8 -*-
import serial
import socket
import subprocess
from time import sleep

host = "127.0.0.1"
port = 10001

Distance_Num = 0;
cmd = "embulk run config.yml"

def main():
    socket_client = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #オブジェクトの作成
    socket_client.connect((host, port))                               #サーバに接続
    
    # シリアル接続するポート
    with serial.Serial("/dev/ttyS5",9600,timeout=None) as ser:
        
        while True:
            ser.reset_input_buffer()  #シリアル通信のバッファをクリア
            line = ser.readline()
            line = line.decode()
            line = line.rstrip('\r\n')
            
            if line == "DRAW":
            	Distance_Num =Distance_Num + 1
            else:
            	Distance_Num = 0;
            print(Distance_Num)
            
            if line == "OFF":
                socket_client.send("OFF".encode('shift-jis'))
            elif Distance_Num == 15:
                Distance_Num = 0
                socket_client.send("DRAW".encode('shift-jis'))
                sleep(10)
                subprocess.call(cmd, shell=True) #csvファイルの更新
                socket_client.send("DONE".encode('shift-jis'))
            elif line == "MOVE":
                socket_client.send("MOVE".encode('shift-jis'))
            else:
                pass #not reach
        
        ser.close() #not reach

if __name__ == '__main__':
    main()