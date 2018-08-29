class Trap
  TRAPS = {
    "ワープゾーン" => {char: "􄄨􄄩", break_rate: 0.06, desc: "フロア内の別の場所にワープする"},
    "硫酸"         => {char: "􄄦􄄧", break_rate: 0.20, desc: "盾が錆びてしまう"},
    "トラばさみ"   => {char: "􄄪􄄫", break_rate: 0.05, desc: "しばらくの間移動できなくなる"},
    "眠りガス"     => {char: "􄄬􄄭", break_rate: 0.20, desc: "しばらくの間眠ってしまう"},
    "石ころ"       => {char: "􄄮􄄯", break_rate: 0.12, desc: "まわりに持っているアイテムをばらまいてしまう"},
    "木の矢のワナ" => {char: "􄄰􄄱", break_rate: 0.05, desc: "どこからともなく木の矢が飛んでくる"},
    "鉄の矢のワナ" => {char: "鉄", break_rate: 0.12, desc: "どこからともなく鉄の矢が飛んでくる"},
    "毒矢のワナ"   => {char: "􄄲􄄳", break_rate: 0.15, desc: "どこからともなく毒矢が飛んでくる"},
    "地雷"         => {char: "􄄴􄄵", break_rate: 0.30, desc: "爆発がおこり、HPが半分になってしまう"},
    "落とし穴"     => {char: "􄄶􄄷", break_rate: 1.00, desc: "下のフロアへ落ちてしまう"},
    "呪いの罠"     => {char: "\u{104370}\u{104371}", break_rate: 0.15, desc: "アイテムが呪われてしまう"},
  }

  attr_reader :name
  attr_accessor :visible
  attr_accessor :active_count
  attr_accessor :trodden

  def initialize(name, visible = false)
    @name = name
    @visible = visible
    @active_count = 0
    @trodden = false
  end

  def char
    TRAPS[@name][:char] || fail
  end

  def desc
    TRAPS[@name][:desc] || fail
  end

  def break_rate
    TRAPS[@name][:break_rate] || fail
  end

end
