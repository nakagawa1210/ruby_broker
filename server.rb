require "socket"

class MsgServer < TCPServer
  def initialize()
    $array = []
    @ID = []
    $array_mu = Mutex.new()
    $recv_lock = 0
    $send_lock = 0
    $recv_lock_time = []
    $send_lock_time = []
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
    when 5 then 5
    else false
    end
  end
  
  def make_responsedata(command,length,dest,msgid,rescode)
    data = command.to_s << '/' << length.to_s << '/' <<  dest.to_s << '/' << msgid.to_s << '/' << rescode.to_s << "\n"
    return data 
  end
  
  def check_id()
    puts "send_lock = #{$send_lock},recv_lock = #{$recv_lock}"
    $send_lock.times do |n|
      puts "#{$send_lock_time[n]},#{$recv_lock_time[n]}"
    end
    return true
  end
  
  def recv_msg(s)
    loop do
      while $array.length == 0
        sleep(0.001)
      end
      
      lock_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      $array_mu.lock
      $recv_lock += 1
      begin      
        recvdata = $array.shift
      ensure
        $array_mu.unlock
      end
      lock_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      $recv_lock_time.push [lock_start, lock_end]
      
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
      lock_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      $array_mu.lock
      $send_lock += 1
      begin
        $array.push senddata
      ensure
        $array_mu.unlock
      end
      lock_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      $send_lock_time.push [lock_start, lock_end] 
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

  res = 0
  
  while true
    Thread.start(gs.accept) do |s|
      loop do
        s.gets
        res = stub.analyze($_,s)
        break if res
      end
      s.close
      if res == 5
        puts "send_lock = #{$send_lock},recv_lock = #{$recv_lock}"
        $send_lock.times do |n|
          puts "#{$send_lock_time[n][0]},#{$send_lock_time[n][1]},#{$recv_lock_time[n][0]},#{$recv_lock_time[n][1]}"
        end
      end
    end
  end
end

main

