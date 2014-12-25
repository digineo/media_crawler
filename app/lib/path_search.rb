class PathSearch

  delegate *%i(
    each_with_hit
    results
    total
  ), to: :@search

  delegate :took, to: :response

  def initialize(params)
    @parsed = QueryParser.new params[:query].to_s
    @params = params
    @search = Path.search request
  end

  def request
    text = @parsed.text.presence
    {
      query: {
        filtered: {
          filter: filters,
          query: {
            function_score: {
              query: text ? { match: { name: @parsed.text } } : { match_all: {}},
              script_score: {
                script: "doc['boost'].isEmpty() ? 1 : doc['boost'].value"
              }
            }
          },
        }
      },
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

  def filters
    filters = []
    @parsed.options.each do |key,value|
      begin
        case key
        when 'host', 'path'
          filters.push term: { key => value }
        when 'size'
          filters.push range: { "size" => PathSearch::Filter::Size.new(value).to_h }
        end
      rescue ArgumentError
        logger.error $!
      end
    end
    filters.any? ? { and: filters } : nil
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


  protected

  def response
    @search.response
  end

end
