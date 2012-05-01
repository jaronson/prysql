class Prysql::Shell < Thor::Shell::Color
  include Pry::Helpers::BaseHelpers

  attr_reader :stdout
  attr_reader :stdin
  attr_reader :stderr

  def initialize(options = {})
    @base, @mute, @padding = nil, false, 0

    @stdout   = options[:stdout] || Pry.output
    @stdin    = options[:stdin]  || Pry.input
    @stderr   = options[:stderr] || $stderr
  end

  def print_result(result, options = {})
    return say('Empty set') if result.size == 0

    options[:headers] = result.fields
    options[:output_format] = options.delete(:vertical) ? :vertical : :sql_table

    print_table(result.to_a, options)
  end

  def print_hash(hash, options = {})
    return if hash.empty?

    rows = hash.to_a.sort{|a,b| a <=> b}

    print_table(rows, options.merge(:lang => :ruby))
  end

  def print_table(rows, options = {})
    table = format_table(rows, options)
    stagger_output(table)
  end

  def format_table(rows, options = {})
    return if rows.empty? && !options[:headers]

    if options[:headers]
      headers = [ options[:headers] ]
    else
      headers = []
    end

    options[:lang] ||= :sql

    options[:formats]   = []
    options[:indent]    = options[:indent].to_i
    options[:truncate]  = terminal_width if options[:truncate] == true

    rows = rows.map{|row| row.map{|v| format_object(v, options[:lang])}}

    rows_and_headers   = headers
    rows_and_headers  += rows unless rows.empty?

    options[:colcount] = rows_and_headers.max{|a,b| a.size <=> b.size }.size

    case options[:output_format]
    when :vertical
    else
      0.upto(options[:colcount] - 1) do |i|
        maxima ||= rows_and_headers.map {|row| row[i] ? row[i].size : 0 }.max
        options[:formats] << "%-#{maxima + 2}s"
        options[:formats][0] = options[:formats][0].insert(0, " " * options[:indent]) if options[:formats][0]
      end
    end

    case options[:output_format]
    when :sql_table
      table = format_sql_table(headers, rows, options)
    when :vertical
      table = format_vertical_table(headers.first, rows, options)
    else
      table = format_default_table(headers, rows, options)
    end

    table.join("\n")
  end

  def format_sql_table(headers, rows, options = {})
    options[:formats] = options[:formats].map{|f| "| #{f}" }

    formatted_headers = format_sql_headers(headers, options) if headers.any?
    formatted_rows    = format_sql_rows(rows, options)

    line = formatted_headers.first.split('|').map{|h| '-' * h.size }.join('+') + '+'

    table = []
    table << line
    table += formatted_headers
    table << line
    table += formatted_rows
    table << line

    table
  end

  def format_vertical_table(headers, rows, options = {})
    table = []
    separator = "#{'*' * 27} %s. row #{'*' * 27}"

    0.upto(options[:colcount] - 1) do |i|
      maxima ||= headers.map {|h| h.size }.max
      format = "%-#{headers[i].size - maxima}s" % ''
      options[:formats] << "#{format}%s"
    end

    rows.each_with_index do |row, i|
      table << separator % (i + 1)
      row.each_with_index do |col, j|
        col       = colorize_sql_token(col)
        formatted = options[:formats][j] % [ "#{headers[j]}: #{col}" ]

        table << formatted
      end
    end

    table
  end

  def format_default_table(headers, rows, options = {})
    table  = []
    table << colorize_table_rows(format_table_rows(headers, options), options[:lang]) if headers.any?
    table << colorize_table_rows(format_table_rows(rows, options), options[:lang])
    table
  end

  def format_sql_headers(headers, options)
    formatted = format_table_rows(headers, options)
    l = "#{formatted.pop} |"
    formatted << l
    formatted
  end

  def format_sql_rows(rows, options)
    rows = colorize_sql_rows(format_table_rows(rows, options))
    highlight(options[:highlight], rows) if options[:highlight]
    rows
  end

  def format_table_rows(rows, options)
    sentences = []

    rows.each do |row|
      sentence = ''

      row.each_with_index do |column, i|
        sentence << options[:formats][i] % column.to_s
      end

      sentence = truncate(sentence, options[:truncate]) if options[:truncate]
      sentences << sentence
    end

    sentences
  end

  def format_object(obj, lang = :ruby)
    return obj if obj.is_a?(String)

    if obj.is_a?(Symbol)
      ":#{obj}"
    elsif obj.is_a?(BigDecimal)
      obj.to_f.to_s
    elsif obj.nil?
      case lang
        when :sql then 'NULL'
        else 'nil'
      end
    elsif obj.respond_to?(:to_s)
      obj.to_s
    else
      obj.inspect
    end
  end

  def colorize_table_rows(rows, lang = :ruby)
    return rows if !Pry.color
    rows.map{|row| CodeRay.scan(row, lang).terminal }
  end

  def colorize_sql_rows(rows)
    return rows unless Pry.color
    rows.map{|row| row.split('|').map{|v| colorize_sql_token(v) }.join('|') + ' |' }
  end

  def colorize_sql_token(str)
    return str unless Pry.color

    case str.strip
      # Integer
      when /^int\([0-9]+\)/, /^[0-9]+$/
        set_color(str, :blue)
      # Float, Decimal
      when /^float\([0-9]+,[0-9]+\)/, /^float$/, /^decimal\([0-9]+,[0-9]+\)/, /^decimal$/, /^[-+]?[0-9]*\.?[0-9]+$/
        set_color(str, :cyan)
      # Date
      when /^datetime$/, /^date$/, /^[0-9]{4}-[0-9]{2}-[0-9]{2}/
        set_color(str, :yellow, :bold)
      # String
      when /^varchar\([0-9]+\)$/, /^char\([0-9]+\)$/
        set_color(str, :green, :bold)
      # Boolean
      when /^tinyint\([0-9]+\)$/
        set_color(str, :magenta)
      when /^true$/
        set_color(str, :green)
      when /^false$/
        set_color(str, :red)
      # Null
      when /^NULL$/
        set_color(str, :cyan, :bold)
      else
        str
    end
  end

  # TODO: This is hacked to only highlight the last match
  # found for search_columns
  def highlight(hi, rows)
    rows.map{|row|
      res = row.scan(/#{hi}/i)

      if res.any?
        offset = Regexp.last_match.offset(0)
        [
          row[0..offset[0]-1],
          set_color(row[offset[0]..offset[1]-1], :green, :bold),
          row[offset[1]..row.size]
        ].join('')
      else
        row
      end
    }
  end

  def newline
    stdout.puts("\n")
  end

  def say_status(*args)
    if args.first.is_a?(Symbol)
      level, msg, options = args
    else
      level, msg, options = :info, args.pop, args.pop
    end

    options ||= {}

    if Pry.color
      colors = case level
        when :success then [ :green , :bold ]
        when :warning then [ :yellow, :bold ]
        when :error   then [ :red,    :bold ]
        else               [ :white ]
      end
    else
      colors = []
    end

    say(msg, :colors => colors)
  end

  def say(message = '', options = {})
    message = message.to_s

    options[:force_new_line] ||= message.to_s !~ /( |\t)$/
    options[:colors] ||= []

    if Pry.color
      if options[:colorize]
        message = CodeRay.scan(message, options[:lang] || :ruby).terminal
      elsif options[:colors].any?
        message = set_color(message, *options[:colors])
      end
    end

    spaces  = "  " * padding
    spaces += " "  * options[:indent].to_i if options[:indent]

    if options[:force_new_line]
      stdout.puts(spaces + message)
    else
      stdout.print(spaces + message)
    end

    stdout.flush
  end

  def pad_array(array, size)
    0.upto(size - 1) do |i|
      array[i] ||= ""
    end
    array
  end
end
