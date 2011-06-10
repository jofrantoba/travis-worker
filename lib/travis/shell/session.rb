require 'net/ssh'
require 'net/ssh/shell'
require 'vagrant'
require 'fileutils'
require 'shellwords'
require 'patches/net_ssh_shell_process'

module Travis
  module Shell
    class Session

      #
      # API
      #


      # VirtualBox VM instance used by the session
      attr_reader :vm

      # Net::SSH session
      # @return [Net::SSH::Connection::Session]
      attr_reader :shell

      # Vagrant log file path
      # @return [String]
      attr_reader :log

      def initialize(env)
        @vm    = env.primary_vm.vm
        @shell = Net::SSH.start(env.config.ssh.host, env.config.ssh.username, :port => 2222, :keys => [env.config.ssh.private_key_path]).shell
        @log   = '/tmp/travis/log/vboxmanage'

        yield(self) if block_given?

        FileUtils.mkdir_p(File.dirname(log))
        sandbox_start
      end

      def execute(command, options = {})
        command = echoize(command) unless options[:echoize] == false

        status = nil
        shell.execute(command) do |process|
          process.on_finish do |p|
            status = p.exit_status
          end
        end
        shell.session.loop { status.nil? }
        status
      end

      def close
        shell.wait!
        shell.close!
        sandbox_rollback
      end



      #
      # Protected
      #

      protected

      def sandbox_start
        vbox_manage "snapshot '#{vm.name}' take 'travis-sandbox'"
      end

      def sandbox_rollback
        vbox_manage "controlvm '#{vm.name}' poweroff"
        vbox_manage "snapshot '#{vm.name}' restore 'travis-sandbox'"
        vbox_manage "startvm --type headless '#{vm.name}'"
      end

      def vbox_manage(cmd)
        system "VBoxManage #{cmd}", :out => log, :err => log
      end
    end # Session
  end # Shell
end # Travis