class Prysql::Interface
  include Prysql::Commands

  attr_reader :host
  attr_reader :username
  attr_reader :password
  attr_reader :database
  attr_reader :options

  attr_reader :client

  def initialize(opts = {})
    opts = opts.clone

    @host = opts.delete(:host) || 'localhost'
    @username = opts.delete(:username)
    @password = opts.delete(:password)
    @database = opts.delete(:database)

    @options  = opts.freeze
  end

  def client
    return @client if @client

    opts = {
      :host     => host,
      :username => username,
      :password => password,
      :database => database,
      :encoding => 'UTF8'
    }.merge(options)

    @client = Mysql2::Client.new(opts)
    @client.query_options.merge!({
      :as => :array,
      :cast_booleans => true
    })
    @client
  end

  def completions
    if @completions.nil? || @completions[:schema] != database
      @completions = get_completions
    end

    @completions[:completions]
  end

  def reconnect!
    @client = nil
    client
  end

  protected
  def get_completions
    completions = []

    client.query("SHOW TABLES").each do |row|
      table = row.first
      completions << table
      client.query(%{
        SELECT COLUMN_NAME
        FROM information_schema.COLUMNS
        WHERE TABLE_NAME = '#{table}'
        AND table_schema = '#{database}'
      }).each do |column_row|
        completions << column_row.first
      end
    end

    { :schema => database, :completions => completions.uniq }
  end
end
