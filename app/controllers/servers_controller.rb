class ServersController < ApplicationController
  
  inherit_resources
  actions :index
  
  def index
    @stats = Resource.indexed.select('count(*) count, sum(filesize) filesize')[0]
  end

  def filelist
    send_file resource.filelist_path
  end
  
end
