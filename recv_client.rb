require 'socket'

class RecvData < Struct.new(:command, :length, :dest, :msgid, :message,
                                :T_1, :T_2, :T_3, :T_4)
  def dataset (data, time, n)
    @recvdata[n].command = data[0]
    length = data[1 ... 5]
    @recvdata[n].length = length
    @recvdata[n].dest = data[6]
    @recvdata[n].msgid = data[7]
    @recvdata[n].message = data[8 ... 8 + length]
    @recvdata[n].T_1 = data[0]
    @recvdata[n].T_2 = data[0]
    @recvdata[n].T_3 = data[0]
    @recvdata[n].T_4 = time
  end 
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

    @recvdata.push RecvData.new(command,
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
    time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      
    RecvData.dataset(data, time, @n)
    @n += 1
 
    break if @n == count
  end

  puts "num,send,svr_in,svr_out,recv"
  @recvdata.each do |s|
    puts "#{s.dest},#{s.T_1},#{s.T_2},#{s.T_3},#{s.T_4}"
  end
end

main
