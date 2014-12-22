require 'rails_helper'

describe ServersController do

  it { should route(:get, 'servers'           ).to action: :index }

  describe "GET index" do
    before do
      get :index
    end

    it { should respond_with :success }
    it { should render_template :index }
  end

end
