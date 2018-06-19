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
  }

  attr_reader :name
  attr_accessor :visible

  def initialize(name, visible = false)
    @name = name
    @visible = visible
  end

  def char
    NAME_TO_CHAR[@name] || fail
  end
end
