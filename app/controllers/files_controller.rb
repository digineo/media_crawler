class FilesController < ApplicationController

  helper_method :parent

  def index

  end

  protected

  def parent
    @server ||= Server.find(params[:server_id])
  end

end
