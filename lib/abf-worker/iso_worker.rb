require_relative 'runners/iso'
require_relative 'inspectors/live_inspector'

module AbfWorker
  class IsoWorker < BaseWorker
    attr_accessor :runner,
                  :live_logger,
                  :file_logger

    def self.perform(options)
      self.new(options).perform
    end

    protected

    def initialize(options)
      @observer_queue       = 'iso_worker_observer'
      @observer_class       = 'AbfWorker::IsoWorkerObserver'
      super options

      output_folder = APP_CONFIG['output_folder']
      Dir.mkdir(output_folder) if not Dir.exists?(output_folder)

      @runner = AbfWorker::Runners::IsoRunner.new(self, options)
      init_live_logger("abfworker::iso-worker-#{@build_id}")
      init_file_logger(output_folder + "/iso_build.log")
      initialize_live_inspector(options['time_living'], "iso#{@build_id}")
    end

    def send_results
      update_build_status_on_abf({
        results: upload_results_to_file_store,
        exit_status: @runner.exit_status
      })
    end

  end

end
