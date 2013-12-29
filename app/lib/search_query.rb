class SearchQuery

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

  attr_reader :results, :filters

  def initialize(params)
    @filters  = SearchFilters.new(params[:query].to_s)
    remaining = @filters.remaining
    
    server_id       = @filters[:server_id]
    duration        = @filters[:duration]
    duration_min    = @filters[:duration_min]
    duration_max    = @filters[:duration_max]
    
    search = Tire::Search::Search.new('resources', load: true)
    search.query do
      filtered do
        # Query-String
        query do
          if remaining.blank?
            all
          else
            # Volltextsuche
            string remaining
          end
        end
      end
    end

    search.highlight :filename, :folder, :options => { :tag => '<strong class="highlight">' } if remaining

    # Facets
    [:server_id, :filesize, :duration, :resolution, :audio_channels, :video_codec, :audio_languages, :subtitle_languages].each do |key|
      if ranges = Ranges[key]
        search.facet key.to_s do
          range key.to_s, ranges.map { |r|
            { from: r.from, to: r.to, include_lower: true, include_upper: false }
          }
        end
      else
        search.facet key do
          terms key
        end
      end
    end

    @results = search.results
  end


end
