class SearchQuery

  Facets = %i(
    server_id
    filesize
    duration
    resolution
    audio_channels
    video_codec
    audio_languages
    subtitle_languages
  )

  Ranges = {
    filesize: [
      Facet::Range.new("0..10m"),
      Facet::Range.new("10m..100m"),
      Facet::Range.new("100m..1g"),
      Facet::Range.new("1g..10g"),
      Facet::Range.new("10g..100g"),
    ],
    duration: [ 
      Facet::Range.new("0..20"),
      Facet::Range.new("20..60"),
      Facet::Range.new("60..120"),
      Facet::Range.new("120..999"),
    ]
  }

  RangesByValues = Hash[Ranges.map{|k,ranges|
    [k, Hash[ranges.map{|v| [v.numeric, v] }]]
  }]

  attr_reader :results, :filters

  def initialize(params)
    @filters  = SearchFilters.new(params[:query].to_s)
=begin
    server_id       = @filters[:server_id]
=end

    options = {}
    query   = @filters.remaining

    @filtered = []
    @aggs     = {}

    @search_definition = {
      query: { filtered: {} },
      aggs:  @aggs,
      highlight: {
        pre_tags: ['<em class="highlight">'],
        post_tags: ['</em>'],
        fields: {
          folder:   { number_of_fragments: 0 },
          filename: { number_of_fragments: 0 },
        }
      }
    }

    Facets.each do |key|
      if ranges = Ranges[key]
        # Range aggregation/filter
        @aggs[key] = {
          range: {
            field: key.to_s,
            ranges: ranges.map { |r|
              { from: r.from, to: r.to }
            }
          }
        }
        if range = filters[key]
          @filtered.push range: { key => {gte: range.begin, lt: range.end} }
        end
      else
        # Term aggregation/filter
        @aggs[key] = {
          terms: {
            field: key.to_s
          }
        }
        if value = filters[key]
          @filtered.push term: {key => value.first}
        end
      end
    end

    # Apply any filters?
    if @filtered.any?
      @search_definition[:query][:filtered][:filter] = {and: @filtered}
    end

    # Search query present?
    if query.present?
      @search_definition[:query][:filtered][:query] = {
        multi_match: {
          query: query,
          fields: ['folder','filename'],
        }
      }
    end

    if options[:sort]
      @search_definition[:sort]  = { options[:sort] => 'desc' }
      @search_definition[:track_scores] = true
    end

    @search_definition[:size] = 50

    @results = Resource.__elasticsearch__.search(@search_definition)
  end


  FacetGroup = Struct.new(:key, :options)

  class Bucket
    attr_reader :count, :key
    def initialize(key, bucket)
      @key    = key
      @bucket = bucket
      @count  = bucket.doc_count
    end

    def to_s
      @bucket.from ? RangesByValues[key.to_sym]["#{@bucket.from.to_i}..#{@bucket.to.to_i}"].to_s : @bucket['key']
    end

    def any?
      count > 0
    end
  end

  def facets
    results.response['aggregations'].map do |key, attr|
      FacetGroup.new key, attr.buckets.map{|b| Bucket.new(key, b) }.select(&:any?)
    end
  end

end
