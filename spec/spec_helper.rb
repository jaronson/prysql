SPEC_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(SPEC_ROOT)
$LOAD_PATH.unshift(File.join(SPEC_ROOT, '..', 'lib'))

require 'pry'
require 'rspec'
require 'thor'
require 'mysql2'

require 'prysql'

# Set I/O streams.
#
# Out defaults to an anonymous StringIO.
#
def redirect_pry_io(new_in, new_out = StringIO.new)
  old_in = Pry.input
  old_out = Pry.output

  Pry.input = new_in
  Pry.output = new_out
  begin
    yield
  ensure
    Pry.input = old_in
    Pry.output = old_out
  end
end

def mock_pry(*args)

  binding = args.first.is_a?(Binding) ? args.shift : binding()

  input = InputTester.new(*args)
  output = StringIO.new

  redirect_pry_io(input, output) do
    binding.pry
  end

  output.string
end

def mock_command(cmd, args=[], opts={})
  output = StringIO.new
  ret = cmd.new(opts.merge(:output => output)).call_safely(*args)
  Struct.new(:output, :return).new(output.string, ret)
end

def redirect_global_pry_input(new_io)
  old_io = Pry.input
    Pry.input = new_io
    begin
      yield
    ensure
      Pry.input = old_io
    end
end

def redirect_global_pry_output(new_io)
  old_io = Pry.output
    Pry.output = new_io
    begin
      yield
    ensure
      Pry.output = old_io
    end
end
