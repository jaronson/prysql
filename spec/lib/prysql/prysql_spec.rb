require 'spec_helper'

describe Prysql do
  context 'class' do
    describe 'constants' do
      it 'should define SQL_PROMPT'
      it 'should define SQL_COMMANDS'
    end

    describe 'methods' do
      describe '#interface' do
        it 'should do something'
      end

      describe '#query_assignment_proc' do
        it 'should do something'
      end

      describe '#setup' do
        it 'should do something'
      end

      describe '#toggle_shell_mode_proc' do
        it 'should do something'
      end

      describe '#host' do
        it 'should do something'
      end

      describe '#username' do
        it 'should do something'
      end

      describe '#database' do
        it 'should do something'
      end
    end
  end
end

describe Prysql::GlobalCommandSet do
  describe 'commands' do
    describe 'prysql' do
    end

    describe 'prysql-mode' do
    end

    describe 'sql-mode' do
    end
  end
end

describe Prysql::SQLModeCommandSet do
  describe 'commands' do
    Prysql::SQL_COMMANDS.each do |sql_command|
      describe "#{sql_command} print command" do
      end
    end

    Prysql::SQL_COMMANDS.each do |sql_command|
      describe "#{sql_command} assignment command" do
      end
    end

    describe 'use command' do
    end
  end
end
