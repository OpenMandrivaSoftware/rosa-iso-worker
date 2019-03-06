module AbfWorker::Runners
  class IsoRunner

    attr_accessor :exit_status

    def initialize(worker, options)
      @worker       = worker
      @params       = options['params']
      @srcpath      = options['srcpath']
      @command      = options['main_script']
      @docker_container = case options['platform']['type']
      when 'mdv'
        'rosalab/rosa2016.1'
      when 'rhel'
        'rosalab/rels7'
      end
      system 'docker pull ' + @docker_container
      @container_name = "iso#{options['id']}"
    end

    def run_script
      puts "Run " + @command

      if @worker.status != AbfWorker::BaseWorker::BUILD_CANCELED
        prepare_script
        exit_status = nil
        final_command = [
          "docker run --name #{@container_name} --rm --privileged=true",
          "--add-host abf-downloads.rosalinux.ru:192.168.76.91",
          "--add-host file-store.rosalinux.ru:192.168.76.92",
          "--device /dev/loop-control:/dev/loop-control",
          "-v #{File.join(ROOT, 'iso_builder')}:/home/vagrant/iso_builder",
          "-v #{APP_CONFIG['output_folder']}:/home/vagrant/results",
          "-v #{APP_CONFIG['output_folder']}:/home/vagrant/archives",
          @docker_container,
          "/bin/bash -c 'cd /home/vagrant/iso_builder; chmod a+x #{@command}; ./#{@command}'"
        ].join(' ')
        process = IO.popen(final_command, 'r', :err=>[:child, :out]) do |io|
          while true
            begin
              break if io.eof
              line = io.gets
              puts line
              @worker.live_logger.log(line)
              @worker.file_logger.log(line)
            rescue => e
              break
            end
          end
          Process.wait(io.pid)
          @exit_status = $?.exitstatus
        end
        @worker.file_logger.close
        if @worker.status != AbfWorker::BaseWorker::BUILD_CANCELED
          if @exit_status.nil? or @exit_status != 0
            @worker.status = AbfWorker::BaseWorker::BUILD_FAILED
          else
            @worker.status = AbfWorker::BaseWorker::BUILD_COMPLETED
          end
        end
	      system "sudo rm -rf #{File.join(ROOT, 'iso_builder')}"
      end
    end

    private

    def prepare_script
      file_name = @srcpath.match(/archive\/(.*)/)[1]
      folder_name = @srcpath.match(/.*\/(.*)\/archive/)[1]
      branch = file_name.gsub('.tar.gz', '')

      command = "cd #{ROOT};"\
                "curl -O -L #{@srcpath};"\
                "tar -zxf #{file_name};"\
                "sudo rm -rf iso_builder;"\
                "mv #{branch} iso_builder;"\
                "rm -rf #{file_name}"
      system command
    end

  end
end
