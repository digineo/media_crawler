class ServersController < ApplicationController
  
  inherit_resources
  actions :index
  
  def index
    @stats = Resource.indexed.all(:select => 'count(*) count, sum(filesize) filesize')[0]
  end
  
end
