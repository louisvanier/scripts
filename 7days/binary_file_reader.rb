class BinaryFileReader
  attr_accessor :ofs
  def initialize(path)
    @path = Pathname(path)
    @data = @path.open("rb", &:read)
    @ofs = 0
  end

  def get(n, offset = @ofs)
    fail! "Trying to read past end of file" if bytes_left < n
    result = @data[offset, n]
    @ofs = offset + n
    result
  end

  # assumes that you've already found { and are looking for }. Does not recurse yet for deeply nested hashes
  def get_hash
    result = ""
    c = "\x00"
    result << c while !eof? && (c = get(1)) && c.ord != 125
    result
  end

  def get_line
    result = ""
    while (!eof?)
        c = get(1)
        break if [10,13].include?(c.ord)
        result << c
    end
    result
  end

  def get_str
    result = ""
    while (!eof?)
        c = get(1)
        break if c.ord < 32 || c.ord > 126
        result << c
    end

    result
  end

  def bytes_left
    @data.size - @ofs
  end

  def eof?
    @data.size == @ofs
  end

  def fail!(message)
    raise "#{message} at #{@path}:#{@ofs}"
  end

  def get_u1
    get(1).unpack("C")[0]
  end

  def get_u2
    get(2).unpack("S")[0]
  end

  def get_u4
    get(4).unpack("L")[0]
  end

  def get_i4
    get(4).unpack("l")[0]
  end
end
