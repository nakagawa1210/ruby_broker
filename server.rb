require "socket"

class Recv
    def initialize()
      
    end
  
    def each
      return enum_for(:each) unless block_given?
      loop do 
        recvdata = $array.shift
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        data = recvdata << ',' << time.to_s
        
        yield data
        break if $array.length == 0
      end
    end
end
  
class MsgServer
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
    when 0 then check_id(data)
    when 1 then send_msg(winsize,s)
    when 2 then recv_msg(s)
    when 9 then true
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
        sleep(0.00001)
        $array_mu.lock
      end
      loop do
        recvdata = $array.shift
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        
        data = recvdata << ',' << time.to_s
        
        s.write(data + "\n")
       
        break if $array.length == 0
      end
    ensure
      $array_mu.unlock
      s.write("8\n")
    end
    
    return false
  end 
  
  def send_msg(winsize,s)
    $array_mu.lock
    begin
      s.write("\n")
      winsize.times do
        s.gets
        break if $_[0] == '8'
        senddata = $_.chomp
        senddata << ',' << Process.clock_gettime(Process::CLOCK_MONOTONIC).to_s
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
        s.gets
        res = stub.analyze($_,s)
        break if res
      end
      s.close
    end
  end
end

main
