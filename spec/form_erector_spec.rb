require 'spec_helper'

describe 'form erector' do
  include Rack::Test::Methods
  include SpecHelper

  describe 'form tag attributes' do
    describe 'action and method for new record' do
      before do
        user = new_user
        app.instance_eval do
          resources(:users) do
            get(new_user){ form_for(user) }
          end
        end
        get '/users/new'
      end

      it { page.should have_css "form[action='http://example.org/users/new']" }
      it { page.should have_css "form[method='post']" }
      it { page.should have_css "form[id='new-user']" }
      it { page.should_not have_css "input[name=_method]" }
    end

    describe 'action and method for existing record' do
      before do
        user = existing_user
        app.instance_eval do
          resources(:users) do
            get(new_user){ form_for(user) }
          end
        end
        get '/users/new'
      end

      it { page.should have_css "form[action='http://example.org/users/1/edit']" }
      it { page.should have_css "form[method='post']" }
      it { page.should have_css "form[id='edit-user']" }
      it { page.should have_xpath "//input[@name='_method' and @value='put']" }
    end

    describe 'overriding method (get) and action and setting html attributes' do
      before do
        user = existing_user
        app.instance_eval do
          resources(:users) do
            get(new_user){ form_for(user, :action => '/users', :method => :get, :class => 'search-form') }
          end
        end
        get '/users/new'
      end

      it { page.should have_css "form[action='http://example.org/users']" }
      it { page.should have_css "form[method='get']" }
      it { page.should_not have_css "input[name=_method]" }
      it { page.should have_css "form.search-form" }
    end
  end
end
