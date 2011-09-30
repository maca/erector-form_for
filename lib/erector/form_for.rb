# encoding: utf-8
require 'sinatra/trails'
require "erector"

libdir = File.dirname( __FILE__)
$:.unshift(libdir) unless $:.include?(libdir)
require "form_for/version"

module Erector
  module FormFor
    class Form < Erector::InlineWidget
      attr_reader :object_name
      needs :action, :method => 'post'

      def initialize app, object, opts, &block
        assigns          = {}
        @app             = app
        @object          = object
        @opts            = opts
        @object_name     = opts.delete(:object_name)
        assigns[:method] = opts.delete(:method)

        if opts.has_key?(:action)
          assigns[:action] = opts.delete(:action)
        end

        if object_is_record?
          @object_name ||= object.class.table_name.to_s.singularize
          if object.new_record?
            assigns[:action] ||= app.path_for("new_#{object_name}") if app.respond_to?(:path_for)
            assigns[:method] ||= 'post'
            opts[:id]        ||= "new-#{object_name}"
          else
            assigns[:action] ||= app.path_for("edit_#{object_name}", object) if app.respond_to?(:path_for)
            assigns[:method] ||= 'put'
            opts[:id]        ||= "edit-#{object_name}"
          end
        end

        super assigns, &block 

        @method = @method.to_s
        @action = @app.url @action
      end

      def fields attrs = {}, &block
        legend_text = attrs.delete(:legend)
        fieldset attrs do
          ol &block
          legend(legend_text) if legend_text
        end
      end

      def form_input field, attrs = {}
        widget WrappedInput.new(@object, @object_name, field, attrs)
      end

      private
      def content
        opts = @opts.merge(:method => @method == 'get' ? 'get' : 'post', :action => @action)
        form opts do
          input :type => "hidden", :name => "_method", :value => @method unless %(get post).include? @method
          if @method != 'get' && @app.env['rack.session'] && @app.env['rack.session']['csrf.token']
            text! Rack::Csrf.csrf_tag(@app.env) 
          end
          input :type => "hidden", :name => "utf8", :value => '✓'
          super
        end
      end

      def object_is_record?
        @object.class.respond_to?(:table_name) && @object.respond_to?(:new_record?)
      end
    end

    class Input < Erector::Widget
      EQUIVALENCIES = {:string => :text, :datetime_local => :'datetime-local', :phone => :tel, :fax => :tel}
      attr_reader :id

      def initialize kind, object, object_name, column, opts
        opts[:name]  ||= object_name ? "#{object_name}[#{column}]" : column
        opts[:id]    ||= [object_name, column].compact.join('-').dasherize
        opts[:value] ||= Hash === object ? object[column] : object.send(column)
        @type   = kind.to_sym 
        @label  = opts.delete(:label) || column.to_s.titleize 
        super opts
      end

      def content
        case @type
        when :boolean
          input :type => :hidden, :value => 0, :name => @name
          label :for => id do
            input assigns.merge(:type => :checkbox, :value => 1)
            text @label
          end
        when :text
          label @label, :for => id
          textarea @value, assigns
        when :select
          label @label, :for => id
          assigns.delete(:collection) || raise("Missing parameter :collection")
          assigns.delete(:value) 
          select assigns do
            @collection.each do |value, text|
              option text || value, :value => value, :selected => value.to_s == @value.to_s ? 'selected' : nil
            end
          end
        when :radio
          assigns.delete(:collection) || raise("Missing parameter :collection")
          assigns.delete(:value) 
          fieldset do
            label @label
            ol do
              @collection.each do |value, label_text|
                li do
                  label do
                    input :value => value, :id => "#{@id}-#{value}".downcase.dasherize, :checked => value.to_s == @value.to_s ? 'checked' : nil
                    text " #{label_text || value}"
                  end
                end
              end
            end
          end
        else
          label @label, :for => id
          input assigns.merge(:type => EQUIVALENCIES[@type] || @type)
        end
      end
    end

    class WrappedInput < Erector::Widget
      needs :as, :id => nil, :required => false

      def initialize object, object_name, column, opts
        assigns = {}

        [:as, :required].each do |key|
          opts.has_key?(key) and assigns[key] = opts.delete(key)
        end

        case column.to_s
        when /email/
          assigns[:as] ||= :email
        when /url/
          assigns[:as] ||= :url
        when /password/
          assigns[:as] ||= :password
        when /search/, /query/, 'q'
          assigns[:as] ||= :search
        when /phone/, /fax/
          assigns[:as] ||= :tel
        end

        if Sequel::Model === object
          column_schema = object.db_schema[column.to_sym]
          assigns[:required] = !column_schema[:allow_null] unless assigns.has_key?(:required)

          type = column_schema[:db_type]
          case type 
          when /char/ 
            opts[:maxlength] ||= /\d+/.match(type)
            assigns[:as]     ||= :string
          else
            assigns[:as]     ||= type.downcase
          end
        end

        super assigns

        case @as = @as.to_sym
        when :hidden, :string, :text, :boolean, :email, :color, :date, :datetime, :'datetime-local', :datetime_local, :email, :file, :image, :month, :number, :password, :range, :search, :tel, :phone, :fax, :time, :url, :week, :select, :radio
          @widget = Input.new @as, object, object_name, column, opts.merge(:required => @required)
        else
          raise ArgumentError, ":as => #{@as.inspect} is not a valid option"
        end

        @wrapper_html      = {:class => []}
        @wrapper_html[:id] = "input-#{@widget.id}"
        @wrapper_html[:class].push(@required ? 'required' : 'optional') 
        @wrapper_html[:class].push @as
      end

      private 
      def content
        li @wrapper_html do
          widget @widget
        end
      end
    end

    module Helpers
      def form_for object, opts = {}, &block
        Form.new(self, object, opts, &block).to_html
      end
    end

    class << self
      def extended base
        base.send :include, Helpers
      end
    end
  end
end
