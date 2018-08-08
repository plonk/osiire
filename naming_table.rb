# 未識別名 本当の名前 プレーヤーが付けた名前
# A        a          α
# B        b          β
class NamingTable
  attr :false_names, :true_names, :nicknames

  def initialize(false_names, true_names)
    if false_names.size != true_names.size
      fail "list length mismatch"
    end
    unless false_names.uniq.size == false_names.size
      fail "duplicate items in false_names"
    end
    unless true_names.uniq.size == true_names.size
      fail "duplicate items in true_names"
    end

    @false_names = false_names.map { |name| name.dup.freeze }.freeze
    @true_names  = true_names.map { |name| name.dup.freeze }.freeze
    n = true_names.size
    @nicknames = [nil] * n
    @identified = [false] * n
  end

  def false_name(true_name)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    fail "not in table" unless include?(true_name)
    @false_names[@true_names.index(true_name)]
  end

  def true_name(true_name)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    fail "not in table" unless include?(true_name)
    true_name
  end

  def nickname(true_name)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    fail "not in table" unless include?(true_name)
    @nicknames[@true_names.index(true_name)]
  end

  def identified?(true_name)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    fail "not in table" unless include?(true_name)
    index = true_names.index(true_name)
    @identified[index]
  end

  def state(true_name)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    fail "not in table" unless include?(true_name)
    index = true_names.index(true_name)
    if @identified[index]
      :identified
    elsif @nicknames[index]
      :nicknamed
    else
      :unidentified
    end
  end

  def include?(true_name)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    index = @true_names.index(true_name)
    if index then true else false end
  end

  def set_nickname(true_name, nickname)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    fail "not in table" unless include?(true_name)
    index = @true_names.index(true_name)
    @nicknames[index] = nickname
  end

  def identify!(true_name)
    fail TypeError, "string expected" unless true_name.is_a?(String)
    fail "not in table" unless include?(true_name)
    index = @true_names.index(true_name)
    @identified[index] = true
  end

  def forget!
    @identified.map! { false }
    @nicknames.map! { nil }
  end

end

if __FILE__ == $0
end
