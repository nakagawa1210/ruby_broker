require "socket"

class MsgServer < TCPServer
  def initialize()
    $array = []
    $array_mu = Mutex.new()
    @ID = []
  end

  def analyze(data,s)
    data = data.chomp
    
    buf = data.partition("/")
    command = buf[0].to_i
    winsize = buf[2].to_i
    
    case command
    when 1 then
      s.write("\n")
      send_msg(winsize,s)
    when 2 then recv_msg(s)
    when 9 then true
    else false
    end
  end
  
  def make_responsedata(command,length,dest,msgid,rescode)
    data = command.to_s << '/' << length.to_s << '/' <<  dest.to_s << '/' << msgid.to_s << '/' << rescode.to_s << "\n"
    return data 
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
    loop do
      $array_mu.lock
      begin
        while $array.length == 0
          $array_mu.unlock
          sleep(0.001)
          $array_mu.lock
        end
        recvdata = $array.shift
      ensure
        $array_mu.unlock
      end

      time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      data = recvdata << ',' << time.to_s << "\n"
        
      s.write(data)
      break if $array.length == 0
    end
    s.write("8\n")
    return false
  end 
  
  def send_msg(winsize,s)
    winsize.times do
      s.gets
      time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      senddata = $_.chomp
      senddata << ',' << time.to_s
        $array_mu.lock
      begin 
        $array.push senddata
      ensure
        $array_mu.unlock
      end
    end
    s.write(make_responsedata(1,2,3,4,5))
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
        s.gets
        res = stub.analyze($_,s)
        break if res
      end
      s.close
    end
  end
end

main

