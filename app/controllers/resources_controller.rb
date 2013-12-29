class ResourcesController < ApplicationController
  
  PAGELEN_DEFAULT = 20
  PAGELEN_MAX     = 500
  
  inherit_resources
  
  def index
    query    = SearchQuery.new(params)
    @results = query.results
    @filters = query.filters
  end

  protected
  
  def per_page
    per_page = params[:per_page].to_i
    per_page = PAGELEN_DEFAULT if per_page < 1
    [per_page, PAGELEN_MAX].min
  end
  
  
end
