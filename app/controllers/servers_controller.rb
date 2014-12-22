class ServersController < ApplicationController

  helper_method :collection

  def index
    #@stats = Resource.indexed.select('count(*) count, sum(filesize) filesize')[0]
  end

  def filelist
    send_file resource.filelist_path
  end

  protected

  def resource
    @server ||= Server.find(params[:id])
  end

  def collection
    Server.all
  end

end
