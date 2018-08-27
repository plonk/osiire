class Trap
  TRAPS = [
    "ワープゾーン",
    "硫酸",
    "トラばさみ",
    "眠りガス",
    "石ころ",
    "矢の罠",
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
    "矢の罠" => "􄄰􄄱",
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
    "矢の罠"           => "どこからともなく木の矢が飛んでくる",
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

  def break_rate
    case @name
    when "ワープゾーン" then 0.06
    when "硫酸"         then 0.20
    when "トラばさみ"   then 0.05
    when "眠りガス"     then 0.20
    when "石ころ"       then 0.12
    when "矢の罠"           then 0.05
    when "毒矢"         then 0.15
    when "地雷"         then 0.30
    when "落とし穴"     then 1.00
    when "呪いの罠"     then 0.15
    end
  end

end
