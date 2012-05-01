class Prysql
  SQL_COMMANDS = CodeRay::Scanners::SQL::COMMANDS + [ 'describe' ]

  CommandSet = Pry::CommandSet.new do
    ASSIGNMENT_MATCHER = /([a-zA-Z_]*)\s+(=)\s+(prysql)(.*)/

    SQL_PROMPT = [
      proc{|*args| "prysql #{Prysql.username}@#{Prysql.host} [#{Prysql.database}] $ " },
      proc{|*args| "prysql #{Prysql.username}@#{Prysql.host} [#{Prysql.database}] * " }
    ]

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
  `local_variable = prysql SELECT * FROM zip_codes`

Available commands:
#{Prysql::Commands.formatted_commands}
BANNER

      def options(opt)
        opt.on :v, :vertical, 'Print output in vertical format',       :optional => true
        opt.on :c, :clear,    'Clear the current input statement',     :optional => true
        opt.on :s, :search,   'Highlight given string',                :optional => true
      end

      def process
        return nil if opts.present?(:clear)

        if arg_string =~ ASSIGNMENT_MATCHER
          assign_local_result
        else
          print_result
        end
      end

      def print_result
        interface     = Prysql.interface
        cmd, cmd_opts = args.shift, {}

        cmd_opts[:vertical] = true if opts.present?(:vertical)

        if interface.has_command?(cmd)
          interface.execute_command(cmd, args, cmd_opts)
        elsif interface.command_is_sql?(cmd)
          interface.execute(args.unshift(cmd), cmd_opts)
        else
          interface.help(cmd)
        end
      end

      def assign_local_result
        var = args.shift
        sql = args.delete_if{|a| a == '=' || a == 'prysql'}.join(' ')

        result = Prysql.interface.execute(sql, :return => true)
        _pry_.inject_local(var, result, _pry_.binding_stack.last)
        result
      end
    end

    alias_command(ASSIGNMENT_MATCHER, 'prysql', {
      :listing     => '= prysql',
      :desc        => 'Assign prysql output to a local variable'
    })

    create_command 'prysql-mode' do
      group 'Prysql'
      description 'Toggle prysql shell mode.'

      def process(*args)
        case _pry_.prompt
        when Prysql::SQL_PROMPT
          _pry_.pop_prompt
          _pry_.custom_completions = Pry::DEFAULT_CUSTOM_COMPLETIONS
          remove_prysql_commands
        else
          _pry_.push_prompt Prysql::SQL_PROMPT
          _pry_.custom_completions = proc{ Prysql.interface.completions }
          add_prysql_commands
        end
      end

      def add_prysql_commands
        Prysql::Commands.available_commands.each do |cmd|
          Pry::Commands.alias_command cmd, "prysql #{cmd}"
        end

        SQL_COMMANDS.each do |cmd|
          Pry::Commands.alias_command /^(#{cmd}.*)/, 'prysql'
        end
      end

      def remove_prysql_commands
        Pry::Commands.delete *Prysql::Commands.available_commands.map{|cmd| cmd }
        Pry::Commands.delete *SQL_COMMANDS.map{|cmd| /^(#{cmd}.*)/ }
      end
    end

    alias_command 'sql-mode', 'prysql-mode'
  end

  class << self
    def setup(options = {})
      @@interface = Prysql::Interface.new(options)
    end

    def interface
      @@interface ||= Prysql::Interface.new
    end

    def host; interface.host; end
    def username; interface.username; end
    def database; interface.database; end
  end
end
