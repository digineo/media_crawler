require 'test_helper'

class StaticControllerTest < ActionController::TestCase
  
  context "static controller" do
    
    should route(:get, '/usage').to(:controller => 'static', :action => 'usage')
    
    context 'on GET to :usage' do
      setup do
        get :usage
      end
      
      should render_template :usage
      should respond_with :success
    end
    
  end
end
