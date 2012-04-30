require 'spec_helper'

describe Prysql::Interface do
  context 'class' do
    describe 'mixins' do
      it 'should include Prysql::Commands' do
        Prysql::Interface.should include(Prysql::Commands)
      end
    end
  end

  context 'instance' do
    let(:options){{
      host: '127.0.0.1',
      username: 'root',
      password: '12354',
      database: 'app_dev'
    }}

    describe 'attributes' do
      it { should     respond_to(:host) }
      it { should_not respond_to(:host=) }

      it { should     respond_to(:username) }
      it { should_not respond_to(:username=) }

      it { should     respond_to(:password) }
      it { should_not respond_to(:password=) }

      it { should     respond_to(:database) }
      it { should_not respond_to(:database=) }

      it { should     respond_to(:options) }
      it { should_not respond_to(:options=) }
    end

    describe 'initialization' do
      it 'should set attributes from options hash' do
        interface = Prysql::Interface.new(options)

        interface.host.should     == options[:host]
        interface.username.should == options[:username]
        interface.password.should == options[:password]
        interface.database.should == options[:database]
      end

      it 'should default host to localhost' do
        options.delete(:host)
        interface = Prysql::Interface.new(options)

        interface.host.should == 'localhost'
      end
    end

    describe 'methods' do
      let(:interface)  { Prysql::Interface.new(options) }
      let(:client_stub){ double('Mysql2::Client',
        :query_options => {},
        :query         => []
      )}

      describe '#client' do
        before(:each) do
          Mysql2::Client.stub(:new).and_return(client_stub)
        end

        it 'should memoize @client' do
          client = interface.client
          Mysql2::Client.should_receive(:new).never
          interface.client.object_id.should == client.object_id
        end

        it 'should create a new instance of Mysql2::Client with options' do
          Mysql2::Client.should_receive(:new).with(options.merge(:encoding => 'UTF8'))

          interface.client
        end

        it 'should update client query_options' do
          Mysql2::Client.should_receive(:new).with(options.merge(:encoding => 'UTF8'))
          client_stub.query_options.should_receive(:merge!).with({
            :as => :array,
            :cast_booleans => true
          })

          interface.client
        end
      end

      describe '#completions' do
        let(:completions){{ :schema => 'app_dev', :completions => [] }}

        before(:each) do
          interface.stub(:get_completions).and_return(completions)
        end

        it 'should memoize @completions' do
          comps = interface.completions
          interface.should_receive(:get_completions).never
          interface.completions.object_id.should == comps.object_id
        end

        it 'should reset completions if schema has changed' do
          comps = interface.completions
          interface.stub(:database).and_return('other_db')
          interface.should_receive(:get_completions).and_return({ :schema => 'other_db', :completions => []})
          interface.completions.object_id.should_not == comps.object_id
        end
      end

      describe '#reconnect!' do
        it 'should set @client to nil and call #client' do
          Mysql2::Client.should_receive(:new).and_return(double('Mysql2::Client', :query_options => {}))
          client = interface.client

          Mysql2::Client.should_receive(:new).and_return(double('Mysql2::Client', :query_options => {}))
          interface.reconnect!

          client.should_not == interface.client
        end
      end
    end
  end
end
