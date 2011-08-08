module FacetsHelper
  
  def render_facet(param, field=nil)
    render :partial => 'facet', :locals => {:param => param, :field => (field || param)}
  end
  
end
