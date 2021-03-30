require "socket"

class MsgServer < TCPServer
  def initialize()
    $array = []
    $array_mu = Mutex.new()
    @ID = []
  end

  def analyze(data,s)
    #data = data.chomp
    
    #buf = data.partition("/")
    #command = buf[0].to_i
    #winsize = buf[2].to_i
    command = data[0]
    winsize = data[1]
    datasize = data[2]
    
    case command
    when 1 then send_msg(winsize,datasize,s)
    when 2 then recv_msg(s)
    when 9 then true
    else false
    end
  end
  
  
  def check_id(iddata, _unused_call)
    @ID.push iddata
=begin   
     Msg::Response.new(length: 1,
                       command: 2,
                       dest: 3,
                       msgid: 4,
                       rescode: 5) 
=end
  end
  
  def recv_msg(s)
    $array_mu.lock
    begin
      while $array.length == 0
        $array_mu.unlock
        sleep(0.001)
        $array_mu.lock
      end
      p length = $array.length
      p size = $array[0][1]
      data = [length,size].pack("i!2")
      s.write(data)
      length.times do
        p recvdata = $array.shift
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        #time = Time.now
        recvdata[6] = time

        s.write(recvdata.pack("i!3uE4"))
        p $array.length
        #break if $array.length == 0
      end
    ensure
      $array_mu.unlock
      ack = 8
      s.write(ack.pack("i"))
    end
    
    return false
  end 
  
  def send_msg(winsize,datasize,s)
    $array_mu.lock
    begin
      winsize.times do
        #s.gets
        #senddata = $_.chomp
        msg = s.readpartial(datasize*1414 + 44)
        p data = msg.unpack("i!3uE4")
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        #time = Time.now
        data[5] = time
        $array.push data
      end
    ensure
      $array_mu.unlock
      ack = [0].pack("i")
      s.write(ack)
    end
    return false
  end
end 


def main ()
  gs = TCPServer.open(50052)
  gs.setsockopt(Socket::IPPROTO_TCP,Socket::TCP_NODELAY,true)
  addr = gs.addr
  addr.shift
  
  stub = MsgServer.new()

  while true
    Thread.start(gs.accept) do |s|
      loop do
        windata = s.readpartial(12).unpack("i!3")
        res = stub.analyze(windata,s)
        break if res
      end
      s.close
    end
  end
end

main

