module ResourcesHelper
  
  def format_resolution(value)
    sprintf "%d:%02d", value/60, value%60
  end
  
  def remove_filter_link(field)
   if @filters[field]
     link_to 'show all', merge_query(field, nil), :title => 'remove filter', :class => 'all'
   end
  end
  
  def facet_link(field, row, text=nil)
    text   ||= row.value
    active   = params[:query].to_s.include?("#{field}:#{row.value}")
    
    html = link_to text, merge_query(field, row.value), :class => active ? 'active' : nil
    html << " (#{row.count})"
    html.html_safe
  end
  
  def merge_query(field, value)
    query = params[:query].to_s.dup
    
    if query.include?("#{field}:")
      query.sub!(/#{field}:\S+/, value ? "#{field}:#{value}" : "")
    else
      query << " #{field}:#{value}"
    end
    
    params.merge(:query => query.strip)
  end
  
  def check_box_group_tag(name, values)
    values.map{|v|
      content_tag :label, check_box_tag("#{name}[]", v, params[name].try(:include?, v)) << h(v)
    }.join(" ").html_safe
  end
  
end
