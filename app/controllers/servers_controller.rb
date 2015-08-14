class ServersController < ApplicationController

  def index
    @hosts = Server.all
  end

end
