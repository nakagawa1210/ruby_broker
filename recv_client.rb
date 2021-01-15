require 'socket'

class MakeRecvData < Struct.new(:command, :length, :dest, :msgid, :message,
                                :T_1, :T_2, :T_3, :T_4)

end

def main
  count = ARGV.size > 0 ?  ARGV[0].to_i : 10
  port = 50052
  s = TCPSocket.open("localhost", port)
  
  @recvdata = []
  
  (0 ... count).each do |num|
    message = ""
    
    length = message.length
    command = 1
    dest = num
    msgid = 2

    @recvdata.push MakeRecvData.new(command,
                                    length,
                                    dest,
                                    msgid,
                                    message,
                                    1,2,3,4)
  end

  length = 1
  command = 2
  dest = 3
  msgid = 4
=begin
  iddata = Msg::IdData.new(length: length,
                           command: command,
                           dest: dest,
                           msgid: msgid)
  
  response = stub.check_id(iddata)
=end
   @n = 0
  
  loop do
    s.write(iddata)
    data = s.gets
      data.T_4 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
      @recvdata[@n] = data
      @n += 1
    end
    break if @n == count
  end

  puts "num,send,svr_in,svr_out,recv"
  @recvdata.each do |s|
    puts "#{s.dest},#{s.T_1},#{s.T_2},#{s.T_3},#{s.T_4}"
  end
end

main
