module Prysql::Commands
  include Pry::Helpers::CommandHelpers

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include,InstanceMethods)
  end

  module ClassMethods
    def shell
      @@shell ||= Prysql::Shell.new
    end

    def commands_with_descriptions
      @@commands_with_descriptions ||= [
        [ 'info',             { desc: 'Print the current Mysql2 client info.' }],
        [ 'setup',            { desc: 'Setup the prysql interface.',   ex: ['{ host: "localhost", username: "root", password: "p12345", database: "testdb" }']}],
        [ 'use',              { desc: 'Switch to the given schema.', ex: ['db_name']}],
        [ 'edit',             { desc: 'Open a new temp file with $EDITOR for query editing to be run on close.' }],
        [ 'show-columns',     { desc: 'Show columns for a given table.', ex: ['users']}],
        [ 'search-columns',   { desc: 'Search across all tables for a column or substring.', ex: ['substr']}],
        [ 'count',            { desc: 'Print the record count for a given table.', ex: ['users']} ],
        [ 'show-all-counts',  { desc: 'Print counts across all tables.' }],
        [ 'execute',          { desc: 'Execute a SQL query.', ex: ['SELECT * FROM users']}]
      ]
    end

    def available_commands
      @@available_commands ||= commands_with_descriptions.map{|cmd, opts| cmd }
    end

    def formatted_commands
      commands = commands_with_descriptions.map{|cmd, opts|
        if opts[:ex]
          example = "`prysql #{cmd} #{opts[:ex].join(', ')}`"
        else
          example = "`prysql #{cmd}`"
        end

        [ cmd, opts[:desc], "e.g.: #{example}" ]
      }

      shell = Prysql::Shell.new
      table = shell.format_table(commands, { :indent => 2, :lang => :text })
    end
  end

  module InstanceMethods
    def shell
      self.class.shell
    end

    def help(cmd = nil, args = [])
      if cmd == 'help'
        shell.say(Prysql::GlobalCommandSet.commands['prysql'].new.help)
      elsif has_command?(cmd)
        method     = command_to_method(cmd)
        parameters = parameters_for(method)

        if args.size > parameters.size
          shell.say_status(:error, "Too many arguments given for prysql #{cmd}")
        else
          missing_args = missing_arguments_for(method, args).map{|a| a.to_s}.join(', ')
          shell.say_status(:error, "Missing required argument(s): #{missing_args}")
        end
      elsif cmd.nil? || cmd.strip == ''
        shell.say_status(:error, 'No command given')
      else
        shell.say_status(:error, "Unknown command `#{cmd}`")
      end

      shell.say_status('Type `prysql help` for more usage information.')
    end

    def info
      shell.say_status('Prysql Info')
      table = [
        [ :host, host ],
        [ :username, username ],
        [ :database, database ]
      ]
      shell.print_table(table, :indent  => 2, :format => :ruby)

      shell.say_status('Mysql2 Client Settings')
      shell.print_hash(client.query_options, { :indent => 2 })
    end

    def setup(options = {})
      Prysql.setup(options)
    end

    def use(schema)
      @database = schema.chomp.strip
      reconnect!
    end

    def edit
      file = File.open('/tmp/.prysql.sql','a+')
      invoke_editor(file.path, 0, false)
      @current_sql = File.read(file.path)
      execute(@current_sql)
    ensure
      file.close if file
    end

    def show_columns(table)
      column_select({
        :conditions => "table_name = '#{table}'",
        :order      => 'column_name'
      })
    end

    def search_columns(search)
      result = column_select({
        :conditions => "column_name LIKE '%#{search}%'",
        :order      => 'table_name',
        :options    => { :highlight => search }
      })
    end

    def count(table)
      result = client.query("SELECT COUNT(*) AS `#{table} count` FROM `#{table}`")
      shell.print_result(result)
    end

    def show_all_counts
      rows = []

      client.query("SHOW TABLES").each do |row|
        table = row.first
        count = client.query("SELECT COUNT(*) FROM #{table}").first.first
        rows << [ table, count ]
      end

      shell.print_table(rows, :headers => [ 'Table', 'Count' ], :format => :sql)
    end

    def execute_command(cmd, args, opts = {})
      method = command_to_method(cmd)
      args  << opts if opts && opts.any?

      if require_parameters(method, args)
        send(method, *args)
      else
        help(cmd, args)
      end
    end

    def execute(sql, opts = {})
      sql = sql.join(' ') if sql.is_a?(Array)

      sql.split(';').each do |q|
        q = q.strip.chomp
        if !q.nil? && !q.empty?
          begin
            result = client.query(q)
          rescue Mysql2::Error => e
            shell.say_status(:error, "Mysql2::Error: #{e.message}")
            shell.say("SQL: #{sql}", { :lang => :sql, :colorize => true, :indent => 2 })
            return nil
          end
          if opts[:output] === false
            return result
          else
            return shell.print_result(result, opts)
          end
        end
      end
    end

    def has_command?(cmd)
      self.class.available_commands.include?(cmd)
    end

    def command_is_sql?(cmd)
      Prysql::SQL_COMMANDS.include?(cmd.downcase)
    end

    private

    def column_select(params = {})
      select = [%{
        SELECT
          TABLE_NAME      AS `table`,
          COLUMN_NAME     AS `column`,
          DATA_TYPE       AS `type`,
          IS_NULLABLE     AS `null?`,
          COLUMN_DEFAULT  AS `default`
        FROM information_schema.COLUMNS
      }]

      conditions = "WHERE table_schema = '#{database}'"
      conditions = [ conditions, params[:conditions] ].join(' AND ') if params[:conditions]

      order = "ORDER BY `#{params[:order]}`" if params[:order]

      statement = [ select, conditions, order ].join("\n")

      options = params[:options] || {}
      execute(statement, options)
    end

    def require_parameters(method, args)
      parameters = parameters_for(method)
      return false if args.size > parameters.size
      return false if missing_arguments_for(method, args).size > 0
      return true
    end

    def missing_arguments_for(method, args)
      required_params = parameters_for(method).select{|m| m.first == :req }
      return [] if required_params.size <= 0

      missing = []
      required_params.each_with_index do |definition, i|
        missing << definition.last if args[i].nil?
      end
      missing
    end

    def parameters_for(method)
      self.class.instance_method(method).parameters
    end

    def command_to_method(cmd)
      cmd.gsub('-','_').to_sym
    end
  end
end
