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
      $array_mu.unlock
    end
end
  
class MsgServer
    def initialize()
      $array = []
      $array_mu = Mutex.new()
      @ID = []
    end

    def analyze(data,s)
      case command = data[0].to_i
      when 0 then check_id(data)
      when 1 then send_msg(data,s)
      when 2 then recv_msg(data,s)
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
    
    def recv_msg(iddata,s)
      $array_mu.lock
      begin
        while $array.length == 0
          $array_mu.unlock
          sleep(0.001)
          $array_mu.lock
        end
        loop do
          recvdata = $array.shift
          time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          
          data = recvdata << ',' << time.to_s
        
          s.write(data + "\n")
          s.gets          
          break if $array.length == 0
        end
      ensure
        $array_mu.unlock
      end
    end 
   
    def send_msg(data,s)
      $array_mu.lock
      begin
        buf = data.chomp
        senddata = buf << ',' << Process.clock_gettime(Process::CLOCK_MONOTONIC).to_s
        $array.push senddata
        s.write("\n")
        while s.gets
          senddata = $_.chomp
          senddata << ',' << Process.clock_gettime(Process::CLOCK_MONOTONIC).to_s
          $array.push senddata
          s.write("\n")
        end
      ensure
        $array_mu.unlock
      end
      
      return "end"
    end
end 


def main ()
    gs = TCPServer.open(50052)
    addr = gs.addr
    addr.shift
    
    stub = MsgServer.new()

    while true
        Thread.start(gs.accept) do |s|
            s.gets
            res = stub.analyze($_,s)         
            s.close
        end
    end
end

main
