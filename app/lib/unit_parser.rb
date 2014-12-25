module UnitParser

  def self.duration(value)
    if value.include?(":")
      h, m = value.split(":")
      h.to_i * 60 + m.to_i
    else
      value.to_i
    end
  end
  
  def self.filesize(value)
    case value
      when /^\d+kb?$/i
        value.to_i.kilobytes
      when /^\d+mb?$/i
        value.to_i.megabytes
      when /^\d+gb?$/i
        value.to_i.gigabytes
      when /^\d+tb?$/i
        value.to_i.terabytes
      else
        value.to_i
    end
  end

end
