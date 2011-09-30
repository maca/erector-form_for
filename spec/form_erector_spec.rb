# encoding: utf-8
require 'spec_helper'

describe 'form erector' do
  include Rack::Test::Methods
  include SpecHelper

  describe 'form tag attributes' do
    describe 'form for record' do
      describe 'action and method for new record' do
        before do
          app.user_form(new_user)
          get '/users/new'
        end

        it { page.should have_css "form[action='http://example.org/users/new']" }
        it { page.should have_css "form[method='post']" }
        it { page.should have_css "form[id='new-user']" }
        it { page.should_not have_css "input[name=_method]" }
      end

      describe 'action and method for existing record' do
        before do
          app.user_form(existing_user)
          get '/users/new'
        end

        it { page.should have_css "form[action='http://example.org/users/1/edit']" }
        it { page.should have_css "form[method='post']" }
        it { page.should have_css "form[id='edit-user']" }
        it { page.should have_xpath "//input[@name='_method' and @value='put']" }
      end

      describe 'overriding method (get) and action and setting html attributes' do
        before do
          app.user_form(existing_user, :action => '/users', :method => :get, :id => 'search-users', :class => 'search-form')
          get '/users/new'
        end

        it { page.should have_css "form[action='http://example.org/users']" }
        it { page.should have_css "form[method='get']" }
        it { page.should_not have_css "input[name=_method]" }
        it { page.should have_css "form#search-users" }
        it { page.should have_css "form.search-form" }
      end
    end

    describe 'form for hash' do
      describe 'action and method for new record and defaulting method to post' do
        before do
          app.user_form({}, :action => '/search')
          get '/users/new'
        end

        it { page.should have_css "form[action='http://example.org/search']" }
        it { page.should have_css "form[method='post']" }
      end

      it 'should requiere action' do
        lambda{ 
          app.user_form({}, :method => 'post') 
          get '/users/new'
        }.should raise_error
      end
    end

    describe 'csrf' do
      it 'should have protection protection off' do
        app.user_form(existing_user)
        get '/users/new'
        page.should_not have_xpath "//input[@name='_csrf' and @type='hidden']"
      end

      it 'should have protection on' do
        app.use Rack::Session::Cookie, :secret => 'my secret'
        app.use Rack::Csrf
        app.user_form(existing_user)
        get '/users/new'
        page.should have_xpath "//input[@name='_csrf' and @type='hidden']"
      end

      it 'should have protection off for get' do
        app.use Rack::Session::Cookie, :secret => 'my secret'
        app.use Rack::Csrf
        app.user_form(existing_user, :method => :get)
        get '/users/new'
        page.should_not have_xpath "//input[@name='_csrf' and @type='hidden']"
      end
    end

    it 'should have utf8 field' do
      app.user_form(existing_user)
      get '/users/new'
      page.should have_xpath "//input[@name='utf8' and @type='hidden' and @value='✓']"
    end

    it 'should pass self to block' do
      app.user_form(new_user) do |form|
        form.should be_a Erector::FormFor::Form
      end
      get '/users/new'
    end
  end

  describe 'formfield' do
    describe 'basic' do
      before do
        app.user_form(new_user) do |form|
          fields
        end
        get '/users/new'
      end
      it { page.should have_xpath "//form/fieldset" }
      it { page.should have_xpath "//form/fieldset/ol" }
      it { page.should_not have_xpath "//form/fieldset/legend" }
    end

    describe 'with legend and attributes' do
      before do
        app.user_form(new_user) do |form|
          fields :legend => 'Basic', :id => 'basic'
        end
        get '/users/new'
      end
      it { page.should have_xpath "//form/fieldset" }
      it { page.should have_xpath "//form/fieldset[@id='basic']" }
      it { page.should have_xpath "//form/fieldset/legend", :text => 'Basic' }
    end
  end

  describe 'inputs' do
    describe 'for record' do
      describe 'basic' do
        before do
          new_user.stub!(:name).and_return('Macario')
          app.user_form(new_user) do
            fields do
              form_input :name
              form_input :about
            end
          end
          get '/users/new'
        end

        describe 'wrap' do
          it { page.should have_xpath "//form/fieldset/ol/li" }
          it { page.should have_css "li#input-user-name" }
          it { page.should have_css "li#input-user-name.required" }
          it { page.should have_css "li#input-user-name.string" }
          it { page.should have_css "li#input-user-about.optional" }
        end

        describe 'input' do
          it { page.should have_xpath "//form/fieldset/ol/li/input" }
          it { page.should have_css "input#user-name" }
          it { page.should have_css "input#user-name[type='text']" }
          it { page.should have_css "input#user-name[name='user[name]']" }
          it { page.should have_css "input#user-name[value='Macario']" }
          it { page.should have_css "input#user-name[maxlength='255']" }
          it { page.should have_css "input#user-name[required]" }
          it { page.should_not have_css "input#user-about[required]" }
        end

        describe 'label' do
          it { page.should have_css "label[for='user-name']" }
          it { page.should have_css "label[for='user-name']", :text => "Name" }
        end
      end

      describe 'overriding defaults' do
        before do
          new_user.stub!(:name).and_return('Macario')
          app.user_form(new_user) do
            fields do
              form_input :name, :required => false, :value => 'Luis', :id => 'nombre', :name => 'nombre', :maxlength => 100, :label => 'Escriba su nombre', :as => 'email'
            end
          end
          get '/users/new'
        end

        describe 'wrap' do
          it { page.should have_xpath "//form/fieldset/ol/li" }
          it { page.should have_css "li#input-nombre" }
          it { page.should have_css "li#input-nombre.optional" }
          it { page.should have_css "li#input-nombre.email" }
        end

        describe 'input' do
          it { page.should have_xpath "//form/fieldset/ol/li/input" }
          it { page.should have_css "input#nombre" }
          it { page.should have_css "input#nombre[type='email']" }
          it { page.should have_css "input#nombre[name='nombre']" }
          it { page.should have_css "input#nombre[value='Luis']" }
          it { page.should have_css "input#nombre[maxlength='100']" }
        end

        describe 'label' do
          it { page.should have_css "label[for='nombre']" }
          it { page.should have_css "label[for='nombre']", :text => "Escriba su nombre" }
        end
      end
    end

    describe 'for hash' do
      before do
        app.user_form({:name => 'Macario', :about => nil}, :action => '/new') do
          fields do
            form_input :name,  :as => :string, :required => true
            form_input :about, :as => :string
          end
        end
        get '/users/new'
      end

      describe 'wrap for required' do
        it { page.should have_xpath "//form/fieldset/ol/li" }
        it { page.should have_css "li#input-name" }
        it { page.should have_css "li#input-name.required" }
        it { page.should have_css "li#input-name.string" }
      end

      describe 'wrap for optional' do
        it { page.should have_css "li#input-about.optional" }
      end

      describe 'input' do
        it { page.should have_xpath "//form/fieldset/ol/li/input" }
        it { page.should have_css "input#name" }
        it { page.should have_css "input#name[type='text']" }
        it { page.should have_css "input#name[name='name']" }
        it { page.should have_css "input#name[value='Macario']" }
      end

      describe 'label' do
        it { page.should have_css "label[for='name']" }
        it { page.should have_css "label[for='name']", :text => "Name" }
      end
    end

    describe 'input' do
      describe 'boolean input with sequel reflection' do
        before do
          app.user_form(new_user) do
            fields { form_input :confirmed }
          end
          get '/users/new'
        end

        it { page.should have_xpath "//form/fieldset/ol/li/label/input[@id='user-confirmed']" }
        it { page.should have_css "input#user-confirmed[type='checkbox']" }
        it { page.should have_css "input#user-confirmed[value='1']" }
        it { page.should have_css "input#user-confirmed[name='user[confirmed]']" }
        it { page.should have_xpath "//form/fieldset/ol/li/input[@type='hidden' and @name='user[confirmed]']" }
        it { page.should have_xpath "//form/fieldset/ol/li/input[@type='hidden' and @value='0']" }
        it { page.should have_xpath "//form/fieldset/ol/li/input[@type='hidden' and @name='user[confirmed]']" }
      end

      %w(hidden color date datetime datetime-local datetime_local email file image month number password range search tel phone fax time url week).each do |type|
        describe "#{type} input" do
          before "should emit type='#{type}'" do
            app.user_form({}, :action => '/search') do
              fields { form_input :any, :as => type }
            end
            get '/users/new'
            @type = 
              case type
              when 'datetime_local' then 'datetime-local'
              when 'phone', 'fax' then 'tel'
              else type end
          end

          it { page.should have_css "input[type='#{@type}']" }
        end
      end

      describe 'type default by name' do
        before do
          app.user_form({}, :action => '/search') do
            fields do
              form_input :email
              form_input :url
              form_input :password
              form_input :password_confirmation
              form_input :search
              form_input :query
              form_input :q
              form_input :phone
              form_input :request_fax
            end
          end
          get '/users/new'
        end
        it { page.should have_css "input#email[type='email']" }
        it { page.should have_css "input#url[type='url']" }
        it { page.should have_css "input#password[type='password']" }
        it { page.should have_css "input#password-confirmation[type='password']" }
        it { page.should have_css "input#search[type='search']" }
        it { page.should have_css "input#query[type='search']" }
        it { page.should have_css "input#q[type='search']" }
        it { page.should have_css "input#phone[type='tel']" }
        it { page.should have_css "input#request-fax[type='tel']" }
      end
    end

    describe 'text input' do
      describe 'text input with sequel reflection' do
        before do
          new_user.stub!(:bio).and_return('Lorem ipsum...')
          app.user_form(new_user) do
            fields { form_input :bio }
          end
          get '/users/new'
        end

        it { page.should have_xpath "//form/fieldset/ol/li/label[@for='user-bio']" }
        it { page.should have_xpath "//form/fieldset/ol/li/textarea[@id='user-bio']" }
        it { page.should_not have_css "texarea[value]" }
        it { page.should have_css "textarea", :text => 'Lorem ipsum...' }
      end
    end

    describe 'select input' do
      describe 'with hash' do
        before do
          app.user_form({:quality => 'best'}, :action => '/search') do
            fields { form_input :quality, :as => :select, :collection => {:worse => 'Worse', :best => 'Best'}  }
          end
          get '/users/new'
        end

        it { page.should have_xpath "//form/fieldset/ol/li/label[@for='quality']" }
        it { page.should have_xpath "//form/fieldset/ol/li/select[@id='quality']" }
        it { page.should have_xpath "//form/fieldset/ol/li/select[@name='quality']" }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='worse']" }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='best']" }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='worse']", :text => 'Worse' }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='best']", :text => 'Best' }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='best' and @selected='selected']" }
      end

      describe 'with multi array' do
        before do
          app.user_form({:quality => 'best'}, :action => '/search') do
            fields { form_input :quality, :as => :select, :collection => [%w(worse Worse), %w(best Best)] }
          end
          get '/users/new'
        end

        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='worse']", :text => 'Worse' }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='best']", :text => 'Best' }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='best' and @selected='selected']" }
      end

      describe 'with array' do
        before do
          app.user_form({:quality => 'Best'}, :action => '/search') do
            fields { form_input :quality, :as => :select, :collection => %w(Worse Best) }
          end
          get '/users/new'
        end

        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='Worse']", :text => 'Worse' }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='Best']", :text => 'Best' }
        it { page.should have_xpath "//form/fieldset/ol/li/select/option[@value='Best' and @selected='selected']" }
      end
    end

    describe 'radio buttons' do
      before do
        app.user_form({:quality => 'best'}, :action => '/search') do
          fields { form_input :quality, :as => :radio, :collection => {:worse => 'Worse', :best => 'Best'}  }
        end
        get '/users/new'
      end

      it { page.should have_xpath "//form/fieldset/ol/li/fieldset" }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/label", :text => 'Quality' }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol" }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li", :count => 2 }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label", :count => 2 }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label/input", :count => 2 }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label/input[@value='worse']" }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label/input[@value='best']" }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label/input[@value='worse' and @id='quality-worse']" }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label/input[@value='best']" }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label/input[@value='best' and @id='quality-best']" }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label", :text => 'Worse' }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label", :text => 'Best' }
      it { page.should have_xpath "//form/fieldset/ol/li/fieldset/ol/li/label/input[@value='best' and @checked='checked']" }
    end

    describe 'translations' do
      describe 'by model attributes' do
        before do
          new_user.stub!(:bio).and_return('Lorem ipsum...')
          app.instance_eval do
            register Sinatra::R18n
            set :default_locale, 'es'
            set :translations, "#{File.dirname __FILE__}/fixtures"
          end

          app.user_form(new_user) do
            fields do 
              form_input :name 
              form_input :bio
              form_input :confirmed
              form_input :any
            end
          end
          get '/users/new'
          puts last_response.body
        end

        it 'should use model attribute translations' do
          page.should have_css "label[for=user-name]", :text => 'Nombre'
        end

        it 'should use form_for label translation' do
          page.should have_css "label[for=user-bio]", :text => 'Biografía'
        end

        it 'should use form_for label translation overriding model attribute' do
          page.should have_css "label[for=user-confirmed]", :text => '¿Confirmado?'
        end

        it 'should resort to titleize column' do
          page.should have_css "label[for=user-any]", :text => 'Any'
        end
      end
    end
  end
end
