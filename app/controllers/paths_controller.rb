class PathsController < ApplicationController
  
  def index
    @search = PathSearch.new(params)
  end

end
