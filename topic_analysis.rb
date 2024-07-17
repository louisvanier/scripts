require 'uea-stemmer'
require 'pragmatic_tokenizer'

class LyricAnalyzer
    def initialize(path:)
        @path = path
        @raw_words = []
        @themes = {}
        @stemmer = UEAStemmer.new
        @tokenizer = PragmaticTokenizer::Tokenizer.new(expand_contractions: true, remove_stop_words: true, punctuation: :none, remove_emoji: true, clean: true, classic_filter: true)
    end

    def raw_words
        return @raw_words unless @raw_words.empty?
        IO.foreach(@path) do |line|
            next if line.chomp == ""
            next if /^\[.*\]$/ =~ line
            @raw_words += @tokenizer.tokenize(line)
        end
        return @raw_words
    end

    def themes
        return @themes unless @themes.empty?
        raw_words.each do |word|
            stem = @stemmer.stem(word)
            if @themes[stem].nil?
                @themes[stem] = 1
            else
                @themes[stem] += 1
            end
        end
        return @themes
    end
end

analyzer = LyricAnalyzer.new(path: ARGV[0])
puts Hash[analyzer.themes.sort_by{|k, v| v}.reverse]
