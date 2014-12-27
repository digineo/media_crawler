class PathSearch

  Aggregations = [
    Aggregation::Term.new(:host),
    Aggregation::Term.new(:type),
    Aggregation::Filesize.new(:size),
  ]

  delegate *%i(
    each_with_hit
    results
    total
  ), to: :@search

  delegate :took, to: :response
  delegate :options, to: :@query


  def initialize(params)
    @query  = QueryParser.new params[:query].to_s
    @params = params
    @search = Path.search request
  end


  # Pagination Stuff (Kaminari)

  def current_page
    @page ||= (@params[:page] || 1).to_i
  end

  def limit_value
    @per_page ||= [(@params[:per_page] || 50).to_i, 500].min
  end

  def total_pages
    (@search.total / @per_page.to_f).ceil
  end

  # aggregations to display
  def aggregations
    Hash[Aggregations.map do |agg|
      [agg, agg.build_results(@search.response.aggregations[agg.key].buckets)]
    end]
  end

  protected

  def response
    @search.response
  end

  # the search request
  def request
    text = @query.text.presence
    {
      query: {
        filtered: {
          filter: filters,
          query: {
            function_score: {
              query: text ? { match: { name: @query.text } } : { match_all: {}},

              # document specific boost
              script_score: {
                script: "doc['boost'].isEmpty() ? 1 : doc['boost'].value"
              }
            }
          },
        }
      },
      aggs: search_aggregations,
      highlight: {
        pre_tags: ['<em class="highlight">'],
        post_tags: ['</em>'],
        fields: {
          name: { number_of_fragments: 0 }
        }
      },
      from: (current_page-1) * limit_value,
      size: limit_value
    }
  end

  # aggregations to use in the search query
  def search_aggregations
    Aggregations.inject({}) do |result, agg|
      key    = agg.key
      ranges = agg.try(:ranges)
      result[key] = if ranges
        # Range aggregation
        {
          range: {
            field: key,
            ranges: ranges.map { |r| { from: r.from, to: r.to } }
          }
        }
      else
        # Term aggregation
        { terms: { field: key } }
      end

      result
    end
  end

  # filters to use in the search query
  def filters
    filters = []
    options.each do |key,value|
      begin
        case key
        when 'host', 'path', 'type'
          filters.push term: { key => value }
        when 'size'
          filters.push range: { "size" => PathSearch::Filter::Filesize.new(value).to_h }
        when 'objects'
          filters.push range: { "objects" => PathSearch::Filter::Int.new(value).to_h }
        end
      rescue ArgumentError
        Rails.logger.error $!.message
        Rails.logger.error $!.backtrace.join("\n")
      end
    end
    filters.any? ? { and: filters } : nil
  end

end
