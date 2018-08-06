# 未識別名 本当の名前 プレーヤーが付けた名前
# A        a          α
# B        b          β
class NamingTable
  attr :false_names, :true_names, :nicknames

  def initialize(false_names, true_names)
    if false_names.size != true_names.size
      fail "list length mismatch"
    end
    @false_names = false_names
    @true_names = true_names
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
  false_names = ["黒い草", "白い草", "赤い草", "青い草", "黄色い草", "緑色の草",
                 "まだらの草", "ツルツルの草", "チクチクの草", "空色の草", "フニャフニャの草",
                 "臭い草", "茶色い草", "ピンクの草"]
  true_names = ["薬草", "高級薬草", "毒けし草", "ちからの種", "幸せの種", "すばやさの種",
                "目薬草", "毒草", "目つぶし草", "まどわし草", "混乱草", "睡眠草", "ワープ草", "火炎草"]

  tbl = NamingTable.new(false_names, true_names)
  p tbl.display_name("薬草")
  p tbl.set_nickname("薬草", "草：や")
  p tbl.display_name("薬草")
  tbl.identify!("薬草")
  p tbl.display_name("薬草")
end
