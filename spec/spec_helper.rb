require 'rubygems'
require 'rspec'
require 'capybara'
require 'rack/test'

$:.unshift File.join(File.dirname( __FILE__), '..', 'lib') 

require 'form_erector'

class User
  class << self
    def table_name
      :users
    end
  end
end

module SpecHelper
  def self.included base
    base.instance_eval do
      let(:app) do
        app = Class.new(Sinatra::Base)
        app.register Sinatra::Trails
        app.register FormErector
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
