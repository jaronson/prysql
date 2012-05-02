module Prysql::Commands
  include Pry::Helpers::BaseHelpers
  include Pry::Helpers::CommandHelpers

  @@commands_with_descriptions = nil
  @@available_commands         = nil
  @@formatted_commands         = nil

  def self.commands_with_descriptions
    @@commands_with_descriptions ||= []
  end

  def self.available_commands
    @@available_commands ||= commands_with_descriptions.map{|cmd, attrs| cmd }
  end

  def self.formatted_commands
    return @@formatted_commands if @@formatted_commands

    rows  = []
    commands_with_descriptions.each{|cmd, attrs|
      examples = attrs[:ex].dup rescue nil
      rows << [ cmd.to_s, attrs[:desc], examples ? "e.g.: `#{examples.shift}`" : '' ]
      examples.each{|ex| rows << [ '', '', "      `#{ex}`"]} if examples
    }

    @@formatted_commands = Prysql::Shell.new.format_table(rows, { :indent => 1, :lang => :text })
  end

  def self.describe(cmd, desc, options = {})
    attrs = { desc: desc }

    if options[:ex]
      examples   = options[:ex].respond_to?(:each) ? options[:ex] : [options[:ex]]
      attrs[:ex] = examples
    end

    attrs[:args] = options[:args] if options[:args]

    commands_with_descriptions << [ method_to_command(cmd), attrs ]
  end

  def self.command_to_method(cmd)
    cmd.to_s.gsub('-','_').to_sym
  end

  def self.method_to_command(meth)
    meth.to_s.gsub('_','-').to_sym
  end

  describe :help, 'Show the help message.'
  def help(cmd = nil, args = [])
    if cmd == 'help'
      shell.say(Prysql::CommandSet.commands['prysql'].new.help)
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

  describe :info, 'Show the mysql client information'
  def info
    shell.say_status('Prysql Settings')
    shell.print_hash(client.query_options, { :indent => 1 })
  end

  describe :setup, 'Setup the prysql interface', args: 'options - Hash'
  def setup(options = {})
    Prysql.setup(options)
  end

  describe :use, 'Switch to the given schema', ex: 'prysql use app_development', args: 'schema - String'
  def use(schema)
    @database = schema.chomp.strip
    reconnect!
  end

  describe :edit, 'Open $EDITOR and edit a query (executed on close).'
  def edit
    file = File.open('/tmp/.prysql.sql','a+')
    invoke_editor(file.path, 0, false)
    @current_sql = File.read(file.path)
    execute(@current_sql)
  ensure
    file.close if file
  end

  def source(filename)
  end

  describe :show_columns, 'Display columns in alphabetical order.'
  def show_columns(table, opts = {})
    column_select({
      :conditions => "table_name = '#{table}'",
      :order      => 'column_name',
      :options    => opts
    })
  end

  # TODO: Patternize it!
  describe :search_columns, 'Search for columns across all tables.', {
    args: [ 'search - (sub)string, SQL regex or Regex' ],
    ex:   [ 'prysql search-columns employ', 'prysql search-columns %employ', 'prysql search-columns /^employ/' ]
  }
  def search_columns(search, opts = {})
    result = column_select({
      :conditions => "column_name LIKE '%#{search}%'",
      :order      => 'table_name',
      :options    => { :highlight => search }.merge(opts)
    })
  end

  describe :count, 'Display the record count for a given table', args: 'table - String'
  def count(table)
    result = query("SELECT COUNT(*) AS `#{table} count` FROM `#{table}`")
    shell.print_result(result)
  end

  describe :show_all_counts, 'Display counts across all tables.', {
    args: 'conditions - String',
    ex:   [ 'prysql show-all-counts', 'prysql show-all-counts > 0', 'prysql show-all-counts <= 100' ]
  }
  def show_all_counts(operator = nil, count = nil)
    rows = []
    sql  =  "SELECT COUNT(*) FROM %s"

    if operator && count
      sql << " HAVING COUNT(*) #{operator} #{count}" if operator && count
    end

    query("SHOW TABLES").each do |row|
      table = row.first
      count = query(sql % table).first
      rows << [ table, count.first ] if count
    end

    shell.print_table(rows, :headers => [ 'Table', 'Count' ], :format => :sql)
  end

  describe :execute, 'Execute a SQL query', {
    args: [ 'sql - String', 'opts - Hash options' ],
    ex:   [ 'prysql execute \'SELECT * FROM sites\'' ]
  }
  def execute(sql, opts = {})
    sql = sql.join(' ') if sql.is_a?(Array)

    sql.split(';').each do |q|
      q = q.strip.chomp
      if !q.nil? && !q.empty?
        begin
          result = query(q)
        rescue Mysql2::Error => e
          shell.say_status(:error, "Mysql2::Error: #{e.message}")
          shell.say("SQL: #{sql}", { :lang => :sql, :colorize => true, :indent => 2 })
          return nil
        end

        if opts[:return]
          return result
        else
          return shell.print_result(result, opts)
        end
      end
    end
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

  def has_command?(cmd)
    return false if cmd.nil?
    Prysql::Commands.available_commands.include?(cmd.to_sym)
  end

  def command_is_sql?(cmd)
    return false unless cmd
    Prysql::SQL_COMMANDS.include?(cmd.downcase)
  end

  def shell
    @shell ||= Prysql::Shell.new
  end

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
    Prysql::Commands.instance_method(method).parameters
  end

  def command_to_method(cmd)
    Prysql::Commands.command_to_method(cmd)
  end

  def method_to_command(meth)
    Prysql::Commands..method_to_command(meth)
  end
end
