require 'pathname'

class 7DaysSaveFileParser
  def initialize(path)
    @path = Pathname(path)
    @data = @path.open("rb", &:read)
    @ofs = 0
  end

  def get(n)
    fail! "Trying to read past end of file" if bytes_left < n
    result = @data[@ofs, n]
    @ofs += n
    result
  end

  def bytes_left
    @data.size - @ofs
  end

  def oef?
    @data.size == @ofs
  end

  def fail!(message)
    raise "#{message} at #{@path}:#{@ofs}"
  end

  def get_u1
    get(1).unpack("C")[0]
  end

  def get_u2
    get(2).unpack("v")[0]
  end

  def get_u4
    get(4).unpack("V")[0]
  end

  def get_i4
    get(4).unpack("l")[0]
  end
end

parser = 7DaysSaveFileParser.new(ARGV[0])
parser.show_me_your_moves
