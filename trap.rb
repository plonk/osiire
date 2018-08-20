class Trap
  TRAPS = [
    "ワープゾーン",
    "硫酸",
    "トラばさみ",
    "眠りガス",
    "石ころ",
    "矢",
    "毒矢",
    "地雷",
    "落とし穴",
    "呪いの罠",
  ]

  NAME_TO_CHAR = {
    "ワープゾーン" => "􄄨􄄩",
    "硫酸" => "􄄦􄄧",
    "トラばさみ" => "􄄪􄄫",
    "眠りガス" => "􄄬􄄭",
    "石ころ" => "􄄮􄄯",
    "矢" => "􄄰􄄱",
    "毒矢" => "􄄲􄄳",
    "地雷" => "􄄴􄄵",
    "落とし穴" => "􄄶􄄷",
    "呪いの罠" => "\u{104370}\u{104371}",
  }

  NAME_TO_DESC     = {
    "ワープゾーン" => "フロア内の別の場所にワープする",
    "硫酸"         => "盾が錆びてしまう",
    "トラばさみ"   => "しばらくの間移動できなくなる",
    "眠りガス"     => "しばらくの間眠ってしまう",
    "石ころ"       => "まわりに持っているアイテムをばらまいてしまう",
    "矢"           => "どこからともなく木の矢が飛んでくる",
    "毒矢"         => "どこからともなく毒の矢が飛んでくる",
    "地雷"         => "爆発がおこり、HPが半分になってしまう",
    "落とし穴"     => "下のフロアへ落ちてしまう",
    "呪いの罠"     => "アイテムが呪われてしまう",
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
    NAME_TO_CHAR[@name] || fail
  end

  def desc
    NAME_TO_DESC[@name] || "???"
  end
end
