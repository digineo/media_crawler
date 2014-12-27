module Aggregation

  class Base
    class_attribute :result_clazz

    self.result_clazz = Struct.new(:result) do
      delegate :[], to: :result
      def to_s
        result['key']
      end
    end

    attr_reader :key
    def initialize(key)
      @key = key
    end

    def build_results(result)
      result.map{|r| result_clazz.new(r) }
    end
  end

  class Term < Base
  end

  class Filesize < Base
    Ranges = [
      Facet::Range.new("0..10m"),
      Facet::Range.new("10m..100m"),
      Facet::Range.new("100m..1g"),
      Facet::Range.new("1g..10g"),
      Facet::Range.new("10g..100g"),
    ]
 
   self.result_clazz = Struct.new(:aggregation, :result) do
     delegate :key, :ranges, to: :aggregation
     delegate :[], to: :result

      def to_s
        [result.from, result.to].map{|v| UnitParser.int_to_str(v.to_i*1024) }.join("..")
      end
   end

    def ranges
      Ranges
    end

    def build_results(result)
      result.map{|r| result_clazz.new(self,r) }
    end
  end

end
