class ServersController < ApplicationController

  def index
    @hosts = Server.all
    @stats = @hosts.stats
  end

end
