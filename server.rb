require "socket"

=begin 
class Recv
    def initialize()
      
    end
  
    def each
      return enum_for(:each) unless block_given?
      loop do 
        recvdata = $array.shift
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        
        yield Msg::RecvData.new(length: recvdata.length,
                                command: recvdata.command,
                                dest: recvdata.dest,
                                msgid: 1,
                                message: recvdata.message,
                                T_1: recvdata.T_1,
                                T_2: recvdata.T_2,
                                T_3: time,
                                T_4: recvdata.T_4)
        break if $array.length == 0
      end
      $array_mu.unlock
    end
  end
=end
  
  
class MsgServer
    def initialize()
      $array = []
      $array_mu = Mutex.new()
      @ID = []
    end

    def analyze(data)
      case command = data[0].to_i
      when 0 then check_id(data)
      when 1 then send_msg(data)
      when 2 then recv_msg(data)
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
    
=begin 
    def recv_msg(iddata, _call)
      $array_mu.lock
      begin
        while $array.length == 0
          $array_mu.unlock
          sleep(0.001)
          $array_mu.lock
        end
        Recv.new().each
      ensure
        #$array_mu.unlock
      end
    end 
=end
   
    def send_msg(data)
      $array_mu.lock
      begin
        data.gsub("\n", ',')
        senddata = data + Process.clock_gettime(Process::CLOCK_MONOTONIC).to_s + ','
        $array.push senddata
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
        Thread.start(gs.accept) do |s|       # save to dynamic variable
            print(s, " is accepted\n")
            while s.gets
                res = stub.analyze($_)
                s.write(res)
            end
            
            print(s, " is gone\n")
            print($array)
            s.close
        end
    end
end

main
