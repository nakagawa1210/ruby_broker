ruby_broker 
===================================

TCP/IP を用いてRuby で作成したメッセージブローカ

ruby_broker 以下のディレクトリに作成したプログラムをおいている．

# 各ディレクトリとファイルの説明

ruby_broker ディレクトリ:作成したプログラムとプログラムを実行するシェルスクリプトが存在するディレクトリ

test.sh:引数にメッセージ送信回数とデータのサイズ(ｋB)，出力するファイルの名前，ウィンドウサイズをとり，プログラムを実行するシェルスクリプト

make_graph.sh:.csv ファイルをgnuplotを用いて.png の図を作成するシェルスクリプト

recv_client.rb:メッセージを受信し，測定した時刻を.log ファイルとしてlogディレクトリ以下に出力する．

send_client.rb:メッセージをサーバに送信する．

server.rb:メッセージを送受信するサーバ

ssh_test.sh:sshでhsc1に接続し，指定した回数grpc_test.shを実行するシェルスクリプト

# 実行手順
(1) 以下のコマンドでクローンする．

$ git clone https://github.com/nakagawa1210/ruby_broker.git

(2) ruby_broker ディレクトリでtest.sh を実行する．以下のコマンドの場合送信メッセージ数100，データサイズ1KB，windowsize 10で実行し，ファイル名が「test_100_1_<実行した年月日>_<実行した時間>」になる．

$ ./test.sh 100 1 test 10

