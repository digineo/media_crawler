module ResourcesHelper
  
  def format_highlight(hit, field)
    highlight = hit.highlight(field)
    if highlight
      highlight.format { |word| "<span class=\"highlight\">#{h word}</span>" }.html_safe
    else
      hit.result.send field
    end
  end
  
  def format_duration(value)
    return unless value
    sprintf "%d:%02d", value/60, value%60
  end
  
  def remove_filter_link(field)
   if @filters[field]
     link_to 'show all', merge_query(field, nil), :title => 'remove filter', class: 'btn btn-xs btn-success'
   end
  end

  def merge_query(field, value)
    query = params[:query].to_s.dup
    
    if query.include?("#{field}:")
      query.sub!(/#{field}:\S+/, value ? "#{field}:#{value}" : "")
    else
      query << " #{field}:#{value}"
    end
    
    params.merge(:query => query.strip, :page => nil)
  end
  
  def check_box_group_tag(name, values)
    values.map{|v|
      content_tag :label, check_box_tag("#{name}[]", v, params[name].try(:include?, v)) << h(v)
    }.join(" ").html_safe
  end
  
end
