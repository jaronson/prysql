require 'spec_helper'

describe Prysql::Shell do
  context 'instance' do
    describe 'attributes' do
      it { should respond_to(:stderr) }
      it { should_not respond_to(:stderr=)}

      it { should respond_to(:stdin) }
      it { should_not respond_to(:stdin=)}

      it { should respond_to(:stdout) }
      it { should_not respond_to(:stdout=)}
    end

    describe 'initialization' do
      it 'should set @base, @mute & @padding' do
        interface.instance_variable_get(:@base).should    == nil
        interface.instance_variable_get(:@mute).should    == false
        interface.instance_variable_get(:@padding).should == 0
      end
    end

    describe 'methods' do
      describe '#colorize_sql_rows' do
        it 'should do something'
      end

      describe '#colorize_sql_token' do
        it 'should do something'
      end

      describe '#colorize_table_rows' do
        it 'should do something'
      end

      describe '#format_default_table' do
        it 'should do something'
      end

      describe '#format_object' do
        it 'should do something'
      end

      describe '#format_sql_headers' do
        it 'should do something'
      end

      describe '#format_sql_rows' do
        it 'should do something'
      end

      describe '#format_sql_table' do
        it 'should do something'
      end

      describe '#format_table' do
        it 'should do something'
      end

      describe '#format_table_rows' do
        it 'should do something'
      end

      describe '#format_vertical_table' do
        it 'should do something'
      end

      describe '#newline' do
        it 'should do something'
      end

      describe '#pad_array' do
        it 'should do something'
      end

      describe '#print_hash' do
        it 'should do something'
      end

      describe '#print_result' do
        it 'should do something'
      end

      describe '#print_table' do
        it 'should do something'
      end

      describe '#say' do
        it 'should do something'
      end

      describe '#say_status' do
        it 'should do something'
      end
    end
  end
end

