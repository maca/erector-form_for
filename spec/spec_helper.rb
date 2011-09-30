require 'rubygems'
require 'rspec'
require 'capybara'
require 'rack/test'
require 'rack/csrf'
require 'sqlite3'
require 'sequel'

$:.unshift File.join(File.dirname( __FILE__), '..', 'lib') 
require 'erector/form_for'

DB = Sequel.sqlite
DB.create_table :users do
  primary_key :id
  String :name, :null => false
  String :about, :fixed => true
  String :any
  Text   :bio
  Boolean :confirmed
end

class User < Sequel::Model
end

module SpecHelper
  def self.included base
    base.instance_eval do
      let(:app) do
        app = Class.new(Sinatra::Base)
        app.register Sinatra::Trails
        app.register Erector::FormFor
        def app.user_form *args, &block
          resources(:users) do
            get(new_user){ form_for(*args, &block) }
          end
        end
        app.set :environment, :test
      end

      let(:new_user) do
        user = User.new
        user.stub!(:new_record?).and_return(true)
        user
      end

      let(:existing_user) do
        user = User.new
        user.stub!(:new_record?).and_return(false)
        user.stub!(:to_param).and_return(1)
        user
      end

      let(:page) do
        Capybara::Node::Simple.new(last_response.body)
      end
    end
  end
end
