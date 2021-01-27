require "socket"

class MsgServer < TCPServer
  def initialize()
    $array = []
    $array_mu = Mutex.new()
    @ID = []
  end

  def analyze(data,s)
    command = data[0].to_i
    
    case command
    when 1 then send_msg(data,s)
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
        sleep(0.1)
        $array_mu.lock
      end
      loop do
        recvdata = $array.shift
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        #time = Time.now
        data = recvdata << ',' << time.to_s
        senddata = data.ljust(5000, "*")
        s.write(senddata)
        break if $array.length == 0
      end
    ensure
      $array_mu.unlock
      s.write("8")
    end
    
    return false
  end 
  
  def send_msg(data,s)
    $array_mu.lock
    begin
      buf = data.partition("/")
      buf = buf[2].partition("*")
      winsize = buf[0].to_i

      winsize.times do |i|
        senddata = s.recv(5000)
        
        buf = senddata.partition("*")
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        
        senddata = buf[0] << ',' << time.to_s
        $array.push senddata
      end
    ensure
      $array_mu.unlock
      s.write("\n")
    end
    return false
  end
end 


def main ()
  gs = TCPServer.open(50052)
  addr = gs.addr
  addr.shift
  
  stub = MsgServer.new()

  while true
    Thread.start(gs.accept) do |s|
      loop do
        r_data = s.recv(8)
        res = stub.analyze(r_data,s)
        break if res
      end
      s.close
    end
  end
end

main
