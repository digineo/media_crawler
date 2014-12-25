class SearchFilters
  
  attr_reader :invalid_fields, :remaining
  
  def initialize(query)
    @filters        = {}
    @invalid_fields = []
    
    @remaining = query.gsub(Resource::FIELD_PATTERN) do |expr|
      key, value = expr.split(":",2)
      key = key.to_sym
      
      case key
        when :audio_channels, :resolution, :server_id
          @filters[key] = value
        when :filesize
          min, max = value.include?("-") ? value.split("-") : value.split("..")
          @filters[key] = UnitParser.filesize(min)..UnitParser.filesize(max)
        when :duration
          min, max = value.include?("-") ? value.split("-") : value.split("..")
          @filters[key] = UnitParser.duration(min)..UnitParser.duration(max)
        when :duration_min, :duration_max
          @filters[key] = UnitParser.duration(value)
        when :video_codec, :audio_codec, :audio_languages, :subtitle_languages
          @filters[key] ||= []
          @filters[key] += value.include?(",") ? value.split(",") : [value.to_s]
        else
          @invalid_fields << key
      end
      
      nil
    end
  end
  
  def [](key)
    @filters[key]
  end

end
