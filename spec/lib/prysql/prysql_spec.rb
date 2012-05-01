require 'spec_helper'

describe Prysql do
  context 'class' do
    describe 'constants' do
      it 'should define SQL_PROMPT' do
        Prysql.stub(:interface).and_return(double('Interface',{
          :username => 'root',
          :host     => 'localhost',
          :database => 'test'
        }))

        base_prompt = 'prysql root@localhost [test]'
        Prysql::SQL_PROMPT.first.call.should == "#{base_prompt} $ "
        Prysql::SQL_PROMPT.last.call.should  == "#{base_prompt} * "
      end

      it 'should define SQL_COMMANDS' do
        Prysql::SQL_COMMANDS.should == CodeRay::Scanners::SQL::COMMANDS + [ 'describe' ]
      end
    end

    describe 'methods' do
      describe '#setup' do
        it 'should assign @@interface a new interface instance with the given options' do
          options = {
            :host     => 'somehost',
            :port     => '3455',
            :username => 'root',
            :password => 'randompass',
            :database => 'testdb',
          }

          Prysql.setup(options)

          Prysql.interface.host.should     == options[:host]
          Prysql.interface.username.should == options[:username]
          Prysql.interface.password.should == options[:password]
          Prysql.interface.database.should == options[:database]
          Prysql.interface.options.should  == { :port => '3455' }
        end
      end

      describe '#interface' do
        it 'should initialize a new prysql interface' do
          Prysql.interface.should be_a(Prysql::Interface)
        end
      end

      describe '#toggle_shell_mode_proc' do
        let(:pry){ double('pry', {
          :pop_prompt   => true,
          :push_prompt  => true,
          :custom_completions= => true,
        })}

        let(:invoke!){ Prysql.toggle_shell_mode_proc.call }

        before(:each) do
          Prysql.stub(:_pry_).and_return(pry)
          Pry::Commands.stub(:delete).and_return(true)
          Pry::Commands.stub(:import).and_return(true)
        end

        context '_pry_.prompt == SQL_PROMPT' do
          before(:each) do
            pry.stub(:prompt).and_return(Prysql::SQL_PROMPT)
          end

          it 'should clear the last prompt' do
            pry.should_receive(:pop_prompt)
            invoke!
          end

          it 'should set _pry_ custom_completions to default' do
            pry.should_receive(:custom_completions=).with(Pry::DEFAULT_CUSTOM_COMPLETIONS)
            invoke!
          end

          it 'should delete the SQL Mode commands' do
            Pry::Commands.should_receive(:delete).with(*Prysql::SQLModeCommandSet.commands.keys)
            invoke!
          end
        end

        context '_pry_.prompt != SQL_PROMPT' do
          before(:each) do
            pry.stub(:prompt).and_return(Pry::DEFAULT_PROMPT)
          end

          it 'should append the SQL_PROMPT' do
            pry.should_receive(:push_prompt).with(Prysql::SQL_PROMPT)
            invoke!
          end

          it 'should set custom completions to the prysql completions proc' do
            pr = proc {}
            Prysql.stub(:completions_proc).and_return(pr)
            pry.should_receive(:custom_completions=).with(pr)
            invoke!
          end

          it 'should import the SQLModeCommandSet' do
            Pry::Commands.should_receive(:import).with(Prysql::SQLModeCommandSet)
            invoke!
          end
        end
      end

      describe '#query_assignment_proc' do
        let(:binding) { double('binding') }
        let(:pry){ double('pry',{
          :binding_stack => [ binding ],
          :inject_local  => true
        })}

        it 'should call _pry_.inject_local with the current binding and result' do
          var       = 'local_var'
          sql       = 'SELECT COUNT(*) FROM users'
          result    = double('Mysql2::Result')
          interface = double('interface', :execute => result)

          Prysql.stub(:_pry_).and_return(pry)
          Prysql.stub(:interface).and_return(interface)

          interface.should_receive(:execute).with(sql, :output => false).and_return(result)
          pry.should_receive(:inject_local).with(var, result, binding)

          Prysql.query_assignment_proc(var, sql).call
        end
      end

      describe 'delegated methods' do
        before(:all) do
          Prysql.setup( :username => 'username', :host => '127.0.0.1', :database => 'app_dev' )
        end

        it 'should delegate host to interface' do
          Prysql.host.should == Prysql.interface.host
        end

        it 'should delegate username to interface' do
          Prysql.username.should == Prysql.interface.username
        end

        it 'should delegate database to interface' do
          Prysql.database.should == Prysql.interface.database
        end
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
