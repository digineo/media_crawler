module PathSearch::Filter

  class Term
  end

  class Int < Term
    OPS = {
      '>'  => 'gt',
      '>=' => 'gte',
      '<'  => 'lt',
      '<=' => 'lte',
    }

    def initialize(value)
      if value.include?("..") # Range?
        min, max = value.split("..")
        @h = {
          "gte" => str_to_bytes(min),
          "lte" => str_to_bytes(max),
        }
      else
        m = /^(>|>=|<|<=)?(\w+)$/.match(value)
        raise ArgumentError unless m
        op = OPS[m[1] || '>=']
        @h = { op => str_to_bytes(m[2]) }
      end
    end

    def to_h
      @h
    end

    def str_to_bytes(str)
      UnitParser.to_int(str)
    end
  end

  class Filesize < Int
    def str_to_bytes(str)
      UnitParser.to_int(str)
    end
  end
end
