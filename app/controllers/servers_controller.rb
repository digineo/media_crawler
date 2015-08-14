class ServersController < ApplicationController

  def show
    #@stats = Resource.indexed.select('count(*) count, sum(filesize) filesize')[0]
  end

end
