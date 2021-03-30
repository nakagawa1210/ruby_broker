require 'socket'

def main
  count = ARGV.size > 0 ?  ARGV[0].to_i : 10
  port = 50052
  s = TCPSocket.open("localhost", port)
  s.setsockopt(Socket::IPPROTO_TCP,Socket::TCP_NODELAY,true)
  
  command = 2
  dest = 3
  msgid = 4

  iddata = [command,dest,msgid].pack("i!3")
  endack = [9,0,0].pack("i!3")

  recvdata = []

  loop do
    p "loop"
    s.write(iddata)
    msgdata = s.readpartial(8).unpack("i!2")
    winsize = msgdata[0]
    datasize = msgdata[1] / 1024
    p winsize
    p datasize
    winsize.times do
      data = s.readpartial(datasize*1414 + 44).unpack("i!3uE4")
      time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      data[7] = time 
      recvdata.push data
    end
    s.readpartial(4)
    break if recvdata.length == count
  end
  s.write(endack)
  s.close
  
  puts "num,send,svr_in,svr_out,recv" 
  recvdata.each do |data|
    puts "#{data[0]},#{data[4]},#{data[5]},#{data[6]},#{data[7]}"
  end
end

main
