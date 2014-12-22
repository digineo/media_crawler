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

    # Prefill and set the filters (top-level `filter` and `facet_filter` elements)
    #
    __set_filters = lambda do |key, f|

      @search_definition[:filter][:and] ||= []
      @search_definition[:filter][:and]  |= [f]

      @search_definition[:facets][key.to_sym][:facet_filter][:and] ||= []
      @search_definition[:facets][key.to_sym][:facet_filter][:and]  |= [f]
    end

    @search_definition = {
      query:  {},
      filter: {},
      facets: {},
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
        @search_definition[:facets][key] = {
          range: {
            field: key.to_s,
            ranges: ranges.map { |r|
              { from: r.from, to: r.to, include_lower: true, include_upper: false }
            }
          },
          facet_filter: {}
        }
      else
        @search_definition[:facets][key] = {
          terms: {
            field: key.to_s
          },
          facet_filter: {}
        }
      end
    end


    unless query.blank?
      @search_definition[:query] = {
        bool: {
          should: [
            { multi_match: {
                query: query,
                fields: ['folder','filename'],
              }
            }
          ]
        }
      }
    else
      @search_definition[:query] = { match_all: {} }
    end

    if options[:video_codec]
      f = { term: { video_codec: @filters[:video_codec] } }

      __set_filters.(:video_codec, f)
    end

    if options[:published_week]
      f = {
        range: {
          published_on: {
            gte: options[:published_week],
            lte: "#{options[:published_week]}||+1w"
          }
        }
      }

      __set_filters.(:categories, f)
      __set_filters.(:authors, f)
    end

    if query.present? && options[:comments]
      @search_definition[:query][:bool][:should] ||= []
      @search_definition[:query][:bool][:should] << {
        nested: {
          path: 'comments',
          query: {
            multi_match: {
              query: query,
              fields: ['body'],
              operator: 'and'
            }
          }
        }
      }
      @search_definition[:highlight][:fields].update 'comments.body' => { fragment_size: 50 }
    end

    if options[:sort]
      @search_definition[:sort]  = { options[:sort] => 'desc' }
      @search_definition[:track_scores] = true
    end


    @results = Resource.__elasticsearch__.search(@search_definition)
  end



  FacetGroup = Struct.new(:key, :options)


  class FacetTerm
    attr_reader :count, :key
    def initialize(key, term)
      @key   = key
      @count = term['count']
      @term  = term['term']
    end
    def to_s
      @term
    end
  end

  class RangeTerm
    attr_reader :count, :key
    def initialize(key, term)
      @key   = key
      @count = term['count']
      @range = RangesByValues[key.to_sym]["#{term['from'].to_i}..#{term['to'].to_i}"]
    end

    def to_s
      @range.to_s
    end
  end

  def facets
    results.response['facets'].map do |key, attr|
      if attr.ranges
        options = attr.ranges.map{|t| RangeTerm.new(key, t) }
      else
        options = attr.terms.map{|t| FacetTerm.new(key, t) }
      end
      FacetGroup.new(key, options)
    end
  end

end
