require 'time'

module AbfWorker::Inspectors
  class LiveInspector
    CHECK_INTERVAL = 10 # 10 sec

    def initialize(worker, time_living, container_name)
      @worker       = worker
      @kill_at      = Time.now + time_living.to_i
      @container_name = container_name
    end

    def run
      @thread = Thread.new do
        while true
          begin
            sleep CHECK_INTERVAL
            stop_build if kill_now?
          rescue => e
          end
        end
      end
      Thread.current[:subthreads] << @thread
    end

    private

    def kill_now?
      if @kill_at < Time.now
        return true
      end
      if status == 'USR1'
        return true
      else
        return false
      end
    end

    def status
      q = 'abfworker::iso-worker-' + @worker.build_id.to_s + '::live-inspector'
      Redis.current.get(q)
    end

    def stop_build
      @worker.status = AbfWorker::BaseWorker::BUILD_CANCELED
      runner = @worker.runner
      system "docker stop #{@container_name}"
    end

  end
end
