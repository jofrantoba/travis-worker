module Travis
  module Worker
    class Worker
      class Factory
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def worker
          Worker.new(vm, queue, reporter, logger, config)
        end

        def vm
          VirtualMachine::VirtualBox.new(name)
        end

        def reporter
          Reporter.new(reporting)
        end

        def logger
          Util::Logging::Logger.new(vm.name)
        end

        def queue
          Messaging.hub('builds')
        end

        def reporting
          Messaging.hub('reporting.jobs')
        end

        def config
          Travis::Worker.config
        end
      end
    end
  end
end
