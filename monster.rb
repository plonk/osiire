# どうして MonsterGenerator のようなものが必要なのだろう？

class StatusEffect
  attr_accessor :caster
  attr_accessor :type, :remaining_duration

  def initialize(type, remaining_duration = Float::INFINITY)
    @type = type
    @remaining_duration = remaining_duration
  end

  def name
    case type
    when :sleep
      "睡眠"
    when :paralysis
      "かなしばり"
    when :held
      "はりつけ"
    when :confused
      "混乱"
    when :hallucination
      "まどわし"
    when :quick
      "倍速"
    when :bomb
      "爆弾"
    when :audition_enhancement
      "兎耳"
    when :olfaction_enhancement
      "豚鼻"
    else
      type.to_s
    end
  end
end

module StatusEffectPredicates
  attr :status_effects

  def paralyzed?
    @status_effects.any? { |e| e.type == :paralysis }
  end

  def asleep?
    @status_effects.any? { |e| e.type == :sleep }
  end

  def held?
    @status_effects.any? { |e| e.type == :held }
  end

  def confused?
    @status_effects.any? { |e| e.type == :confused }
  end

  def hallucinating?
    @status_effects.any? { |e| e.type == :hallucination }
  end

  def quick?
    @status_effects.any? { |e| e.type == :quick }
  end

  def bomb?
    @status_effects.any? { |e| e.type == :bomb }
  end

  def nullified?
    @status_effects.any? { |e| e.type == :nullification }
  end

  def audition_enhanced?
    @status_effects.any? { |e| e.type == :audition_enhancement }
  end

  def olfaction_enhanced?
    @status_effects.any? { |e| e.type == :olfaction_enhancement }
  end

end

class Monster
  # mimic.rb による生成。
  MIMIC_TABLE = 
[{:char=>"􄁴􄁵",
  :name=>"ミミック",
  :max_hp=>15,
  :exp=>25,
  :strength=>5,
  :defense=>5,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック2歳",
  :max_hp=>18,
  :exp=>29,
  :strength=>6,
  :defense=>5,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック3歳",
  :max_hp=>21,
  :exp=>33,
  :strength=>7,
  :defense=>5,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック4歳",
  :max_hp=>24,
  :exp=>37,
  :strength=>8,
  :defense=>5,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック5歳",
  :max_hp=>27,
  :exp=>42,
  :strength=>9,
  :defense=>6,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック6歳",
  :max_hp=>30,
  :exp=>46,
  :strength=>10,
  :defense=>6,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック7歳",
  :max_hp=>33,
  :exp=>50,
  :strength=>11,
  :defense=>6,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック8歳",
  :max_hp=>36,
  :exp=>54,
  :strength=>12,
  :defense=>6,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック9歳",
  :max_hp=>39,
  :exp=>58,
  :strength=>13,
  :defense=>6,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック10歳",
  :max_hp=>42,
  :exp=>63,
  :strength=>14,
  :defense=>7,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック11歳",
  :max_hp=>45,
  :exp=>134,
  :strength=>15,
  :defense=>7,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック12歳",
  :max_hp=>48,
  :exp=>142,
  :strength=>16,
  :defense=>7,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック13歳",
  :max_hp=>51,
  :exp=>150,
  :strength=>17,
  :defense=>7,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック14歳",
  :max_hp=>54,
  :exp=>158,
  :strength=>18,
  :defense=>7,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック15歳",
  :max_hp=>57,
  :exp=>168,
  :strength=>19,
  :defense=>8,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック16歳",
  :max_hp=>60,
  :exp=>176,
  :strength=>20,
  :defense=>8,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック17歳",
  :max_hp=>63,
  :exp=>184,
  :strength=>21,
  :defense=>8,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック18歳",
  :max_hp=>66,
  :exp=>192,
  :strength=>22,
  :defense=>8,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック19歳",
  :max_hp=>69,
  :exp=>200,
  :strength=>23,
  :defense=>8,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック20歳",
  :max_hp=>72,
  :exp=>210,
  :strength=>24,
  :defense=>9,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック21歳",
  :max_hp=>75,
  :exp=>218,
  :strength=>25,
  :defense=>9,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック22歳",
  :max_hp=>78,
  :exp=>226,
  :strength=>26,
  :defense=>9,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック23歳",
  :max_hp=>81,
  :exp=>234,
  :strength=>27,
  :defense=>9,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック24歳",
  :max_hp=>84,
  :exp=>242,
  :strength=>28,
  :defense=>9,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック25歳",
  :max_hp=>87,
  :exp=>252,
  :strength=>29,
  :defense=>10,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック26歳",
  :max_hp=>90,
  :exp=>260,
  :strength=>30,
  :defense=>10,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック27歳",
  :max_hp=>93,
  :exp=>268,
  :strength=>31,
  :defense=>10,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック28歳",
  :max_hp=>96,
  :exp=>276,
  :strength=>32,
  :defense=>10,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック29歳",
  :max_hp=>99,
  :exp=>284,
  :strength=>33,
  :defense=>10,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック30歳",
  :max_hp=>102,
  :exp=>294,
  :strength=>34,
  :defense=>11,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック31歳",
  :max_hp=>105,
  :exp=>604,
  :strength=>35,
  :defense=>11,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック32歳",
  :max_hp=>108,
  :exp=>620,
  :strength=>36,
  :defense=>11,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック33歳",
  :max_hp=>111,
  :exp=>636,
  :strength=>37,
  :defense=>11,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック34歳",
  :max_hp=>114,
  :exp=>652,
  :strength=>38,
  :defense=>11,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック35歳",
  :max_hp=>117,
  :exp=>672,
  :strength=>39,
  :defense=>12,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック36歳",
  :max_hp=>120,
  :exp=>688,
  :strength=>40,
  :defense=>12,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック37歳",
  :max_hp=>123,
  :exp=>704,
  :strength=>41,
  :defense=>12,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック38歳",
  :max_hp=>126,
  :exp=>720,
  :strength=>42,
  :defense=>12,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック39歳",
  :max_hp=>129,
  :exp=>736,
  :strength=>43,
  :defense=>12,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック40歳",
  :max_hp=>132,
  :exp=>756,
  :strength=>44,
  :defense=>13,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック41歳",
  :max_hp=>135,
  :exp=>772,
  :strength=>45,
  :defense=>13,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック42歳",
  :max_hp=>138,
  :exp=>788,
  :strength=>46,
  :defense=>13,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック43歳",
  :max_hp=>141,
  :exp=>804,
  :strength=>47,
  :defense=>13,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック44歳",
  :max_hp=>144,
  :exp=>820,
  :strength=>48,
  :defense=>13,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック45歳",
  :max_hp=>147,
  :exp=>840,
  :strength=>49,
  :defense=>14,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック46歳",
  :max_hp=>150,
  :exp=>856,
  :strength=>50,
  :defense=>14,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック47歳",
  :max_hp=>153,
  :exp=>872,
  :strength=>51,
  :defense=>14,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック48歳",
  :max_hp=>156,
  :exp=>888,
  :strength=>52,
  :defense=>14,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック49歳",
  :max_hp=>159,
  :exp=>904,
  :strength=>53,
  :defense=>14,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック50歳",
  :max_hp=>162,
  :exp=>1848,
  :strength=>54,
  :defense=>15,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック51歳",
  :max_hp=>165,
  :exp=>1880,
  :strength=>55,
  :defense=>15,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック52歳",
  :max_hp=>168,
  :exp=>1912,
  :strength=>56,
  :defense=>15,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック53歳",
  :max_hp=>171,
  :exp=>1944,
  :strength=>57,
  :defense=>15,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック54歳",
  :max_hp=>174,
  :exp=>1976,
  :strength=>58,
  :defense=>15,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック55歳",
  :max_hp=>177,
  :exp=>2016,
  :strength=>59,
  :defense=>16,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック56歳",
  :max_hp=>180,
  :exp=>2048,
  :strength=>60,
  :defense=>16,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック57歳",
  :max_hp=>183,
  :exp=>2080,
  :strength=>61,
  :defense=>16,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック58歳",
  :max_hp=>186,
  :exp=>2112,
  :strength=>62,
  :defense=>16,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック59歳",
  :max_hp=>189,
  :exp=>2144,
  :strength=>63,
  :defense=>16,
  :action_point_recovery_rate=>2},
 {:char=>"􄉼􄉽",
  :name=>"ミミック60歳",
  :max_hp=>192,
  :exp=>2184,
  :strength=>64,
  :defense=>17,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック61歳",
  :max_hp=>195,
  :exp=>2216,
  :strength=>65,
  :defense=>17,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック62歳",
  :max_hp=>198,
  :exp=>2248,
  :strength=>66,
  :defense=>17,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック63歳",
  :max_hp=>201,
  :exp=>2280,
  :strength=>67,
  :defense=>17,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック64歳",
  :max_hp=>204,
  :exp=>2312,
  :strength=>68,
  :defense=>17,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック65歳",
  :max_hp=>207,
  :exp=>2352,
  :strength=>69,
  :defense=>18,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック66歳",
  :max_hp=>210,
  :exp=>2384,
  :strength=>70,
  :defense=>18,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック67歳",
  :max_hp=>213,
  :exp=>2416,
  :strength=>71,
  :defense=>18,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック68歳",
  :max_hp=>216,
  :exp=>2448,
  :strength=>72,
  :defense=>18,
  :action_point_recovery_rate=>4},
 {:char=>"􄉼􄉽",
  :name=>"ミミック69歳",
  :max_hp=>219,
  :exp=>2480,
  :strength=>73,
  :defense=>18,
  :action_point_recovery_rate=>4},
 {:char=>"􄉾􄉿",
  :name=>"ミミック70歳",
  :max_hp=>222,
  :exp=>2512,
  :strength=>74,
  :defense=>15,
  :action_point_recovery_rate=>4},
 {:char=>"􄉾􄉿",
  :name=>"ミミック71歳",
  :max_hp=>215,
  :exp=>2408,
  :strength=>72,
  :defense=>14,
  :action_point_recovery_rate=>4},
 {:char=>"􄉾􄉿",
  :name=>"ミミック72歳",
  :max_hp=>210,
  :exp=>2352,
  :strength=>70,
  :defense=>14,
  :action_point_recovery_rate=>4},
 {:char=>"􄉾􄉿",
  :name=>"ミミック73歳",
  :max_hp=>205,
  :exp=>2288,
  :strength=>68,
  :defense=>13,
  :action_point_recovery_rate=>4},
 {:char=>"􄉾􄉿",
  :name=>"ミミック74歳",
  :max_hp=>200,
  :exp=>2232,
  :strength=>66,
  :defense=>13,
  :action_point_recovery_rate=>4},
 {:char=>"􄉾􄉿",
  :name=>"ミミック75歳",
  :max_hp=>195,
  :exp=>2168,
  :strength=>64,
  :defense=>12,
  :action_point_recovery_rate=>4},
 {:char=>"􄉾􄉿",
  :name=>"ミミック76歳",
  :max_hp=>190,
  :exp=>2112,
  :strength=>62,
  :defense=>12,
  :action_point_recovery_rate=>4},
 {:char=>"􄁴􄁵",
  :name=>"ミミック77歳",
  :max_hp=>185,
  :exp=>2048,
  :strength=>60,
  :defense=>11,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック78歳",
  :max_hp=>180,
  :exp=>1992,
  :strength=>58,
  :defense=>11,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック79歳",
  :max_hp=>175,
  :exp=>1928,
  :strength=>56,
  :defense=>10,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック80歳",
  :max_hp=>170,
  :exp=>936,
  :strength=>54,
  :defense=>10,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック81歳",
  :max_hp=>165,
  :exp=>904,
  :strength=>52,
  :defense=>9,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック82歳",
  :max_hp=>160,
  :exp=>876,
  :strength=>50,
  :defense=>9,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック83歳",
  :max_hp=>155,
  :exp=>844,
  :strength=>48,
  :defense=>8,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック84歳",
  :max_hp=>150,
  :exp=>816,
  :strength=>46,
  :defense=>8,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック85歳",
  :max_hp=>145,
  :exp=>784,
  :strength=>44,
  :defense=>7,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック86歳",
  :max_hp=>140,
  :exp=>756,
  :strength=>42,
  :defense=>7,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック87歳",
  :max_hp=>135,
  :exp=>724,
  :strength=>40,
  :defense=>6,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック88歳",
  :max_hp=>130,
  :exp=>696,
  :strength=>38,
  :defense=>6,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック89歳",
  :max_hp=>125,
  :exp=>664,
  :strength=>36,
  :defense=>5,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック90歳",
  :max_hp=>120,
  :exp=>318,
  :strength=>34,
  :defense=>5,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック91歳",
  :max_hp=>115,
  :exp=>302,
  :strength=>32,
  :defense=>4,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック92歳",
  :max_hp=>110,
  :exp=>288,
  :strength=>30,
  :defense=>4,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック93歳",
  :max_hp=>105,
  :exp=>272,
  :strength=>28,
  :defense=>3,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック94歳",
  :max_hp=>100,
  :exp=>258,
  :strength=>26,
  :defense=>3,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック95歳",
  :max_hp=>90,
  :exp=>232,
  :strength=>24,
  :defense=>2,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック96歳",
  :max_hp=>80,
  :exp=>208,
  :strength=>22,
  :defense=>2,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック97歳",
  :max_hp=>70,
  :exp=>182,
  :strength=>20,
  :defense=>1,
  :action_point_recovery_rate=>2},
 {:char=>"􄁴􄁵",
  :name=>"ミミック98歳",
  :max_hp=>60,
  :exp=>158,
  :strength=>18,
  :defense=>1,
  :action_point_recovery_rate=>2},
 {:char=>"􄍖􄍗",
  :name=>"ミミック99歳",
  :max_hp=>50,
  :exp=>132,
  :strength=>16,
  :defense=>0,
  :action_point_recovery_rate=>1}]

  SPECIES = [
    {char: "􄁂􄁃",
     name: "スライム",
     max_hp: 5,
     exp: 2,
     strength: 2,
     defense: 2,
     drop_rate: 4.fdiv(256),
     asleep_rate: 0.5,
    },
    {char: "􄉢􄉣",
     name: "緑スライム",
     max_hp: 7,
     exp: 3,
     strength: 3,
     defense: 2,
     drop_rate: 6.fdiv(256),
     asleep_rate: 0.5,
    },
    {char: "􄉤􄉥",
     name: "紫スライム",
     max_hp: 5,
     exp: 500,
     strength: 50,
     defense: 99,
     drop_rate: 9.fdiv(256),
     asleep_rate: 0.5,
    },
    # --------
    {char: "\u{104350}\u{104351}",
     name: "ワラビー",
     max_hp: 6,
     exp: 3,
     strength: 2,
     defense: 3,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "\u{104352}\u{104353}",
     name: "緑ワラビー",
     max_hp: 25,
     exp: 22,
     strength: 14,
     defense: 7,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "\u{104354}\u{104355}",
     name: "紫ワラビー",
     max_hp: 80,
     exp: 300,
     strength: 35,
     defense: 10,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    # --------
    {char: "􄁆􄁇",
     name: "コウモリ",
     max_hp: 7,
     exp: 2,
     strength: 3,
     defense: 1,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "􄁈􄁉",
     name: "オオウミウシ",
     max_hp: 7,
     exp: 3,
     strength: 2,
     defense: 4,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "􄁊􄁋",
     name: "ツバメ",
     max_hp: 5,
     exp: 2,
     strength: 3,
     defense: 9,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "􄁐􄁑",
     name: "催眠術師",
     max_hp: 16,
     exp: 12,
     strength: 6,
     defense: 11,
     drop_rate: 0.33,
     asleep_rate: 0.0,
     trick_range: :reach},
    {char: "􄁒􄁓",
     name: "ピューシャン",
     max_hp: 9,
     exp: 5,
     strength: 4,
     defense: 15,
     drop_rate: 0.01,
     asleep_rate: 0.5,
     trick_range: :line},
    # --------------
    {char: "􄉴􄉵",
     name: "ファンガス",
     max_hp: 14,
     exp: 8,
     strength: 6,
     defense: 5,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄉶􄉷",
     name: "青ファンガス",
     max_hp: 40,
     exp: 60,
     strength: 20,
     defense: 8,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄉸􄉹",
     name: "桃色ファンガス",
     max_hp: 88,
     exp: 127,
     strength: 27,
     defense: 12,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄉺􄉻",
     name: "緑ファンガス",
     max_hp: 120,
     exp: 1200,
     strength: 58,
     defense: 15,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :reach},
    # ------------
    {char: "􄁖􄁗",
     name: "グール",
     max_hp: 10,
     exp: 7,
     strength: 4,
     defense: 15,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "􄁘􄁙",
     name: "木乃伊",
     max_hp: 16,
     exp: 16,
     strength: 10,
     defense: 19,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "􄁚􄁛",
     name: "ノーム",
     max_hp: 20,
     exp: 10,
     strength: 0,
     defense: 16,
     drop_rate: 1.0,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄁜􄁝",
     name: "ハゲタカ",
     max_hp: 27,
     exp: 25,
     strength: 10,
     defense: 16,
     drop_rate: 0.16,
     asleep_rate: 0.5,
    },
    {char: "􄁞􄁟",
     name: "ソーサラー",
     max_hp: 23,
     exp: 15,
     strength: 10,
     defense: 16,
     drop_rate: 0.01,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄁄􄁅",
     name: "銀メタル",
     max_hp: 3,
     exp: 500,
     strength: 30,
     defense: 49,
     drop_rate: 1.0,
     asleep_rate: 0.0,
    },
    {char: "􄉠􄉡",
     name: "金メタル",
     max_hp: 3,
     exp: 500,
     strength: 30,
     defense: 49,
     drop_rate: 1.0,
     asleep_rate: 0.0,
     action_point_recovery_rate: 4,
    },
    {char: "􄁠􄁡",
     name: "おめん武者",
     max_hp: 35,
     exp: 40,
     strength: 15,
     defense: 26,
     drop_rate: 0.16,
     asleep_rate: 0.5,
    },
    {char: "􄁢􄁣",
     name: "アクアター",
     max_hp: 30,
     exp: 25,
     strength: 0,
     defense: 19,
     drop_rate: 0.01,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄁤􄁥",
     name: "どろぼう猫",
     max_hp: 40,
     exp: 20,
     strength: 0,
     defense: 17,
     drop_rate: 0.0,
     asleep_rate: 0.0,
     trick_range: :reach},
    {char: "􄄤􄄥",
     name: "動くモアイ像",
     max_hp: 45,
     exp: 50,
     strength: 18,
     defense: 27,
     drop_rate: 0.33,
     asleep_rate: 0.0,
    },
    {char: "􄁨􄁩",
     name: "四人トリオ",
     max_hp: 60,
     exp: 10,
     strength: 11,
     defense: 3,
     drop_rate: 0.0,
     asleep_rate: 1.0,
     action_point_recovery_rate: 4,
    },
    {char: "􄁪􄁫",
     name: "白い手",
     max_hp: 72,
     exp: 40,
     strength: 7,
     defense: 23,
     drop_rate: 0.0,
     asleep_rate: 0.0,
    },
    {char: "􄁬􄁭",
     name: "ゴーレム",
     max_hp: 52,
     exp: 180,
     strength: 32,
     defense: 27,
     drop_rate: 0.33,
     asleep_rate: 0.5,
    },
    {char: "􄈬􄈭",
     name: "ボンプキン",
     max_hp: 70,
     exp: 30,
     strength: 12,
     defense: 23,
     drop_rate: 0.01,
     asleep_rate: 0.5,
    },
    {char: "􄁰􄁱",
     name: "パペット",
     max_hp: 36,
     exp: 40,
     strength: 13,
     defense: 23,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄁲􄁳",
     name: "ゆうれい",
     max_hp: 60,
     exp: 150,
     strength: 17,
     defense: 27,
     drop_rate: 0.0,
     asleep_rate: 0.5,
    },
    {char: "􄄠􄄡",
     name: "トロール",
     max_hp: 51,
     exp: 380,
     strength: 51,
     defense: 21,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :none},
    {char: "􄉆􄉇",
     name: "目玉",
     max_hp: 62,
     exp: 250,
     strength: 31,
     defense: 27,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :sight},
    {char: "􄉈􄉉",
     name: "緑目玉",
     max_hp: 62,
     exp: 250,
     strength: 31,
     defense: 27,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :sight},
    {char: "􄉊􄉋",
     name: "赤目玉",
     max_hp: 62,
     exp: 250,
     strength: 31,
     defense: 27,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     trick_range: :sight},
    {char: "􄁸􄁹",
     name: "化け狸",
     max_hp: 80,
     exp: 20,
     strength: 9,
     defense: 14,
     drop_rate: 0.0,
     asleep_rate: 0.5,
    },
    {char: "􄁺􄁻",
     name: "土偶",
     max_hp: 70,
     exp: 150,
     strength: 17,
     defense: 24,
     drop_rate: 0.0,
     asleep_rate: 0.5,
     trick_range: :reach},
    {char: "􄄢􄄣",
     name: "デビルモンキー",
     max_hp: 78,
     exp: 600,
     strength: 26,
     defense: 25,
     drop_rate: 0.16,
     asleep_rate: 0.5,
     action_point_recovery_rate: 4,
    },
    {char: "􄁼􄁽",
     name: "マルスボース",
     max_hp: 75,
     exp: 750,
     strength: 51,
     defense: 29,
     drop_rate: 0.16,
     asleep_rate: 0.5,
    },
    {char: "􄁾􄁿",
     name: "竜",
     max_hp: 100,
     exp: 3000,
     strength: 68,
     defense: 30,
     drop_rate: 0.75,
     asleep_rate: 0.5,
     trick_range: :line}
  ]

  SPECIES.concat(MIMIC_TABLE)

  class << self
    def make_monster(name)
      definition = SPECIES.find { |r| r[:name] == name }
      fail "no such monster: #{name}" if definition.nil?

      asleep_rate = definition[:asleep_rate] || 0.0
      state = (rand() < asleep_rate) ? :asleep : :awake
      return Monster.new(definition,
                         state, [1,1], nil)
    end
  end

  attr :defense, :exp
  attr_accessor :drop_rate
  attr_accessor :hp, :max_hp, :strength
  attr_accessor :state, :facing, :goal
  attr_accessor :item
  attr :trick_range
  attr_accessor :invisible
  attr_accessor :action_point, :action_point_recovery_rate
  attr_accessor :group
  attr_accessor :impersonating_name, :impersonating_char

  include StatusEffectPredicates

  def initialize(definition,
                 state, facing, goal)
    @char     = definition[:char] || fail
    @name     = definition[:name] || fail
    @max_hp   = definition[:max_hp] || fail
    @strength = definition[:strength] || fail
    @defense  = definition[:defense] || fail
    @exp      = definition[:exp] || fail
    @drop_rate = definition[:drop_rate] || 0.0

    @state = state
    @facing = facing
    @goal = goal

    @hp = @max_hp

    @status_effects = []
    @item = nil
    case @name
    when "催眠術師", "どろぼう猫", "四人トリオ"
      # 攻撃されるまで動き出さないモンスター
      @status_effects << StatusEffect.new(:paralysis, Float::INFINITY)
    when "ノーム"
      @item = Gold.new(rand(250..1500))
    when "白い手", "動くモアイ像"
      @status_effects << StatusEffect.new(:held, Float::INFINITY)
    when "メタルヨテイチ"
      @status_effects << StatusEffect.new(:hallucination, Float::INFINITY)
      @item = Item::make_item("幸せの種")
    when "化け狸"
      @impersonating_name = @name
      @impersonating_char = @char
    when "ボンプキン"
      @status_effects << StatusEffect.new(:bomb, Float::INFINITY)
    end

    @trick_range = definition[:trick_range] || :none

    case @name
    when "ゆうれい"
      @invisible = true
    else
      @invisible = false
    end

    @action_point = 0
    @action_point_recovery_rate = definition[:action_point_recovery_rate] || 2
  end

  # state = :awake の操作は別。モンスターの特殊な状態を解除して動き出
  # させる。
  def on_party_room_intrusion
    case @name
    when "催眠術師", "どろぼう猫", "四人トリオ"
      # 攻撃されるまで動き出さないモンスター
      @status_effects.reject! { |e| e.type == :paralysis }
    when "動くモアイ像"
      @status_effects.reject! { |e| e.type == :held }
    end
  end

  def char
    case @name
    when "ボンプキン"
      if hp < 1.0
        "\u{104238}\u{104239}" # puff of smoke
      elsif !nullified? && bomb? && hp <= max_hp/2
        '􄁮􄁯'
      else
        @char
      end
    when "化け狸"
      if hp < 1.0
        @char
      else
        @impersonating_char
      end
    when "動くモアイ像"
      if held?
        @char
      else
        "\u{104066}\u{104067}"
      end
    else
      if hp < 1.0
        "\u{104238}\u{104239}" # puff of smoke
      else
        @char
      end
    end
  end

  def reveal_self!
    if @name == "化け狸"
      @impersonating_name = @name
      @impersonating_char = @char
    end
  end

  def name
    if @name == "化け狸"
      @impersonating_name
    else
      @name
    end
  end

  def tipsy?
    @name == "コウモリ" || @name == "ゆうれい"
  end

  def trick_rate
    case @name
    when "白い手"
      1.0
    when '催眠術師'
      0.25
    when 'ファンガス'
      0.33
    when 'ノーム'
      0.5
    when 'ピューシャン'
      0.75
    when "アクアター"
      0.5
    when "パペット"
      0.5
    when "土偶"
      0.5 # HP 0.25 / ちから 0.25
    when "目玉"
      0.25
    when "どろぼう猫"
      0.5
    when "竜"
      0.5
    when "ソーサラー"
      0.33
    else
      0.0
    end
  end

  def single_attack?
    case @name
    when "ツバメ", "四人トリオ"
      true
    else
      false
    end
  end

  def divide?
    case @name
    when "グール"
      true
    else
      false
    end
  end

  def poisonous?
    case @name
    when 'ファンガス', '土偶'
      true
    else
      false
    end
  end

  def undead?
    case @name
    when '木乃伊', 'ゆうれい'
      true
    else
      false
    end
  end

  def hp_maxed?
    @hp == @max_hp
  end

  def damage_capped?
    @name == "メタルヨテイチ"
  end

  def teleport_on_attack?
    @name == "メタルヨテイチ"
  end

  PHYLOGENY = [
    ["スライム", "緑スライム", "紫スライム"]
  ]

  def descendant
    PHYLOGENY.each do |series|
      # 演算子の優先度がよくわかってない。
      if (i = series.index(@name)) && (i < series.size - 1)
        return series[i + 1]
      end
    end
    return nil
  end

  def ancestor
    PHYLOGENY.each do |series|
      if (i = series.index(@name)) && (i > 0)
        return series[i - 1]
      end
    end
    return nil
  end

private

end
