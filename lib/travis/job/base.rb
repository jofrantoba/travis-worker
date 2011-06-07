module Travis
  module Job
    # Job base class. Implements an observer pattern so Reporters can hook in
    # unobstrusively, holds the payload data and provides the main public `work!`
    # method.
    class Base
      class << self
        def base_dir
          @@base_dir ||= Pathname.new('/tmp/travis/builds')
        end

        def base_dir=(base_dir)
          @@base_dir = Pathname.new(base_dir)
        end
      end

      include Travis::Shell, Travis::Job::Stdout

      attr_reader :payload, :observers

      def initialize(payload)
        @payload   = Hashie::Mash.new(payload)
        @observers = []
      end

      def work!
        start
        result = perform
        finish(result)
      end

      def repository
        @repository ||= Repository.new(payload.repository.slug, build.config)
      end

      def config
        repository.config ||= Hashie::Mash.new
      end

      def build
        payload.build ||= Hashie::Mash.new
      end

      protected

        def start
        end

        def update(data)
        end

        def finish(data)
        end

        def notify(event, *args)
          observers.each do |observer|
            observer.send(:"on_#{event}", self, *args) if observer.respond_to?(:"on_#{event}")
          end
        end

        def chdir(&block)
          FileUtils.mkdir_p(build_dir)
          Dir.chdir(build_dir, &block)
        end

        def build_dir
          @build_dir ||= self.class.base_dir.join(repository.slug)
        end
    end
  end
end