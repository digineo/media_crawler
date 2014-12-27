module UnitParser

  def self.duration(value)
    if value.include?(":")
      h, m = value.split(":")
      h.to_i * 60 + m.to_i
    else
      value.to_i
    end
  end
  
  def self.int(value)
    case value
      when /^\d+(\.\d*)?kb?$/i
        value.to_f.kilobytes
      when /^\d+(\.\d*)?mb?$/i
        value.to_f.megabytes
      when /^\d+(\.\d*)?gb?$/i
        value.to_f.gigabytes
      when /^\d+(\.\d*)?tb?$/i
        value.to_f.terabytes
      else
        value.to_i
    end
  end

  def self.int_to_str(val)
    return 0 if val.to_f == 0.0
    return "#{val/(1024**4)}t" if val % 1024**4 == 0
    return "#{val/(1024**3)}g" if val % 1024**3 == 0
    return "#{val/(1024**2)}m" if val % 1024**2 == 0
    return "#{val/1024}k"      if val % 1024 == 0
    return val
  end

end
