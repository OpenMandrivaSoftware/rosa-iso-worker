module AbfWorker
  class LiveLogger
    LOG_DUMP_INTERVAL = 10 #10 seconds
    LOG_SIZE_LIMIT    = 100 # 100 lines
    def initialize(key_name)
      @key_name  = key_name
      @buffer    = []
      @log_mutex = Mutex.new
      Thread.current[:subthreads] << Thread.new do
        loop do
          sleep LOG_DUMP_INTERVAL
          next if @buffer.empty?
          @log_mutex.synchronize do
            str = @buffer.join
            Redis.current.setex(@key_name, LOG_DUMP_INTERVAL + 5, str) rescue nil
          end
        end
      end
    end

    def log(message)
      line = message.to_s
      unless line.empty?
        @log_mutex.synchronize do
          @buffer.shift if @buffer.size > LOG_SIZE_LIMIT
          @buffer << line
        end
      end
    end

  end
end
