class FilesController < ApplicationController

  def index
    @host = params[:id].to_s
    @uri = "ftp://" << (@host.include?(":") ? "[#{@host}]" : @host) << "/"
  end

end
