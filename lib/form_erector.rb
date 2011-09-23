require "sinatra/trails"
require "erector"

libdir = File.dirname( __FILE__)
$:.unshift(libdir) unless $:.include?(libdir)
require "form_erector/version"

module FormErector
  include Erector::Mixin

  class Form < Erector::InlineWidget
    def initialize app, object, opts, &block
      super &block
      @object    = object
      table_name = object.class.table_name

      if action = opts.delete(:action)
        @action = app.url(action)
      end

      if method = opts.delete(:method)
        @method = method.to_s
      end

      if object.new_record?
        id         = "new_#{table_name.to_s.singularize}"
        @action  ||= app.url_for(id)
        @method  ||= 'post'
      else
        id         = "edit_#{table_name.to_s.singularize}"
        @action  ||= app.url_for(id, @object)
        @method  ||= 'put'
      end

      @opts = opts.merge(:id => id.gsub('_', '-'))
    end

    def content
      opts = @opts.merge(:method => @method == 'get' ? 'get' : 'post', :action => @action)
      form opts do
        input :type => "hidden", :name => "_method", :value => @method unless %(get post).include? @method
        super
      end
    end
  end
  
  module Helpers
    def form_for object, opts = {}, &block
      Form.new(self, object, opts, &block).to_html
    end
  end

  class << self
    def registered base
      base.helpers Helpers
    end
  end
end
