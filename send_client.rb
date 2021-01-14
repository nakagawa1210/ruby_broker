require "socket"

class MakeSendArray
  def initialize(count, datasize)
    @senddata = []
    (0 ... count).each do |num|
      #message = makepaket(datasize)
      message = "message"
      length = message.length
      command = 1
      dest = num
      
      @senddata.push make_senddata(command,
                                   length,
                                   dest,
                                   message)
    end
  end

  def makepaket(size)
    count = size * 1024
    data = "#{size}kBdata".ljust(count, "*")
    return data
  end
  
  def each
    return enum_for(:each) unless block_given?
    @senddata.each do |data|
      senddata = data + Process.clock_gettime(Process::CLOCK_MONOTONIC).to_s
      yield senddata
    end
  end

  def make_senddata(command,length,dest,message)
    data = command.to_s + length.to_s + dest.to_s + message
    return data 
  end
end


def main()
  count = ARGV.size > 0 ?  ARGV[0].to_i : 100
  datasize = ARGV.size > 1 ?  ARGV[1].to_i : 1
  window_size = ARGV.size > 2 ?  ARGV[2].to_i : 1
  port = 50052
  s = TCPSocket.open("localhost", port)

  if (count < window_size)
    puts"count < window_size"
    exit
  end

  loop_count = count / window_size

  senddata = MakeSendArray.new(window_size,datasize)

  loop_count.times do
    senddata.each{|data| s.write(data + "\n")}
    print(s.gets)
  end
  
  s.close
end

main
