require 'strscan'

class QueryParser
  
  attr_reader :text, :options

  def initialize(input)
    @options = {}
    words    = []
    scanner  = StringScanner.new input
    word     = ""
    quotes   = false
    while char = scanner.getch
      case char
      when '"'
        quotes = !quotes
      when /\s/
        if quotes
          word << char
        else
          words << word
          word = ""
        end
      else
        word << char
      end
    end

    words << word if word != ""

    remaining = []
    while word = words.shift
      if m = /^([a-z]+):(.+)$/.match(word)
        key, val = word.split(":",2)
        @options[key] = val
      else
        remaining << word
      end
    end

    @text = remaining.join(" ")
  end
  
  def [](key)
    @options[key]
  end

end
