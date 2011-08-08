class ResourcesController < ApplicationController
  
  PAGELEN_DEFAULT = 20
  PAGELEN_MAX     = 500
  
  inherit_resources
  
  protected
  
  def collection
    query = params[:query].to_s.dup
    
    @filters = {}
    
    query.gsub!(Resource::FIELD_PATTERN) do |expr|
      key, value = expr.split(":",2)
      key = key.to_sym
      
      case key
        when :audio_channels, :resolution
          @filters[key] = value
        when :duration
          min, max = value.include?("-") ? value.split("-") : value.split("..")
          @filters[key] = parse_duration(min)..parse_duration(max)
        when :duration_min, :duration_max
          @filters[key] = parse_duration(value)
        when :video_codec, :audio_codec, :audio_language, :subtitle_language
          @filters[key] ||= []
          @filters[key] += value.include?(",") ? value.split(",") : [value.to_s]
      end
      
      nil
    end
    
    duration        = @filters[:duration]
    duration_min    = @filters[:duration_min]
    duration_max    = @filters[:duration_max]
    
    facets = {
      :resolution         => @filters[:resolution],
      :video_codec        => @filters[:video_codec],
      :audio_channels     => @filters[:audio_channels],
      :audio_languages    => @filters[:audio_language],
      :subtitle_languages => @filters[:subtitle_language],
    }
    
    
    
    @resources ||= resource_class.search do
      
      paginate(:page => params[:page], :per_page => per_page)
      
      keywords query do
        highlight :path
      end
      
      with(:duration).between(duration) unless duration.blank?
      with(:duration).greater_than(duration_min) unless duration_min.blank?
      with(:duration).less_than(duration_max)    unless duration_max.blank?
      
      for field, value in facets
        filter = with(field, value) unless value.blank?
        facet field, :exclude => filter
      end
      
      facet :duration do
        row 0..20 do
          with :duration, 0..20
        end
        row 21..60 do
          with :duration, 21..60
        end
        row 61..120 do
          with :duration, 61..120
        end
        row 121..999 do
          with :duration, 121..999
        end
      end
    end
    
  end
  
  def per_page
    per_page = params[:per_page].to_i
    per_page = PAGELEN_DEFAULT if per_page < 1
    [per_page, PAGELEN_MAX].min
  end
  
  def parse_duration(value)
    if value.include?(":")
      h, m = value.split(":")
      h.to_i * 60 + m.to_i
    else
      value.to_i
    end
  end
  
end
