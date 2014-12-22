module Facet

  class Base
  end

  class Range
    attr_accessor :from, :to, :key
    
    def initialize(str)
      @key       = str
      @from, @to = self.class.parse_sizerange(str)
    end

    def to_s
      @key
    end

    def numeric
      "#{@from}..#{@to}"
    end

    def self.parse_sizerange(str)
      if m = str.match(/^(\d+[kmg]?)\.\.(\d+[kmg]?)$/)
        [ parse_size(m[1]), parse_size(m[2]) ]
      end
    end

    def self.parse_size(str)
      if (val = str.to_i).to_s == str
        return val
      end

      case str[-1]
      when 'k' then val.kilobyte
      when 'm' then val.megabyte
      when 'g' then val.gigabyte
      else raise ArgumentError, "invalid size: #{str}"
      end
    end
  end


end
