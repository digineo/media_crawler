module PathSearch::Filter

  class Size
    OPS = {
      '>'  => 'gt',
      '>=' => 'gte',
      '<'  => 'lt',
      '<=' => 'lte',
    }

    def initialize(value)
      m = /^(>|>=|<|<=)?(\w+)$/.match(value)
      raise ArgumentError unless m
      op = OPS[m[1] || '>=']
      @h = { op => UnitParser.filesize(m[2])/1024 }
    end

    def to_h
      @h
    end
  end
end
