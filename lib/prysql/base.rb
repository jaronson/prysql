class Prysql
  SQL_PROMPT = [
    proc{|*args| "prysql #{Prysql.username}@#{Prysql.host} [#{Prysql.database}] $ " },
    proc{|*args| "prysql #{Prysql.username}@#{Prysql.host} [#{Prysql.database}] * " }
  ]

  SQL_COMMANDS = CodeRay::Scanners::SQL::COMMANDS + [ 'describe' ]

  GlobalCommandSet = Pry::CommandSet.new do
    create_command 'prysql' do |cmd|
      group 'Prysql'
      description 'Pry mysql interface.'
      banner <<-BANNER
Usage:
  prysql [COMMAND] [ARGUMENTS] [--vertical]
  prysql [SQL]

Pass a command name or SQL query (unquoted) directly to prysql.

Examples:
  `prysql count users`
  `prysql SELECT id, email FROM users`

Available commands:
#{Prysql::Interface.formatted_commands}
BANNER

      def options(opt)
        opt.on :v, :vertical, 'Print output in vertical format', :optional => true
      end

      def process
        interface = Prysql.interface
        cmd       = args.shift
        cmd_opts  = {}

        return interface.help if cmd.nil?

        cmd_opts[:vertical] = true if opts.present?(:vertical)

        if interface.has_command?(cmd)
          interface.execute_command(cmd, args, cmd_opts)
        elsif interface.command_is_sql?(cmd)
          args.unshift(cmd)
          interface.execute(args, cmd_opts)
        else
          interface.help(cmd)
        end
      end
    end

    create_command 'prysql-mode' do
      group 'Prysql'
      description 'Toggle prysql shell mode.'

      def process(*args)
        instance_eval &Prysql.toggle_shell_mode_proc
      end
    end

    alias_command 'sql-mode', 'prysql-mode'

    create_command(/([a-zA-Z_]+)\s+=\s+prysql(.*)/, :listing => "= prysql ...") do |var, sql|
      group 'Prysql'
      description 'Assign prysql output to a local variable.'

      def process(var, sql)
        instance_eval &Prysql.query_assignment_proc(var, sql)
      end
    end
  end

  SQLModeCommandSet = Pry::CommandSet.new do
    SQL_COMMANDS.each do |sql_command|
      create_command(/^(#{sql_command}.*)/i, :listing => "#{sql_command.upcase} ...") do |sql|
        group 'Prysql shell mode'
        description "Perform a SQL #{sql_command.upcase} statement."

        def process(sql)
          Prysql.interface.execute(sql)
        end
      end

      create_command(/^(use)(.*)/i, :listing => 'USE ...') do |cmd, db|
        group 'Prysql shell mode'
        description 'Switch databases.'

        def process(cmd, db)
          Prysql.interface.use(db)
          # Reset shell mode
          2.times{ instance_eval &Prysql.toggle_shell_mode_proc }
        end
      end

      create_command(/([a-zA-Z_]+)\s+=\s+(#{sql_command}.*)/i, :listing => "= #{sql_command.upcase} ...") do |var, sql|
        group 'Prysql shell mode'
        description "Assign the output of a SQL #{sql_command} statement to a local variable."

        def process(var, sql)
          instance_eval &Prysql.query_assignment_proc(var, sql)
        end
      end
    end
  end

  class << self
    def setup(options = {})
      @@interface = Prysql::Interface.new(options)
    end

    def interface
      @@interface ||= Prysql::Interface.new
    end

    def toggle_shell_mode_proc
      proc do
        case _pry_.prompt
        when Prysql::SQL_PROMPT
          _pry_.pop_prompt
          _pry_.custom_completions = Pry::DEFAULT_CUSTOM_COMPLETIONS
          Pry::Commands.delete *Prysql::SQLModeCommandSet.commands.keys
        else
          _pry_.push_prompt Prysql::SQL_PROMPT
          _pry_.custom_completions = proc{ Prysql.interface.completions }
          Pry::Commands.import Prysql::SQLModeCommandSet
        end
      end
    end

    def query_assignment_proc(var, sql)
      proc do
        binding = _pry_.binding_stack.last
        result = Prysql.interface.execute(sql, :output => false)
        _pry_.inject_local(var, result, binding)
      end
    end

    def host; interface.host; end
    def username; interface.username; end
    def database; interface.database; end
  end
end
