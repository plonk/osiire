
class Gold < Struct.new(:amount)
  def char; '＊' end
end

class Item
  TYPES = [
    ['凸', 'ナン']
  ]

  class << self
    def make_item(name)
      row = TYPES.find { |r| r[1] == name }
      fail "no such item: #{name}" if row.nil?

      char, name  = row
      return Item.new(char, name)
    end
  end

  attr :char, :name

  def initialize(char, name)
    @char     = char
    @name     = name
  end

  def to_s
    name
  end
end
