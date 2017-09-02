# どうして MonsterGenerator のようなものが必要なのだろう？

class Monster
  SPECIES = [
    # char, name, max_hp, exp, strength, defense
    ['S', 'スライム', 5, 1, 2, 1],            # 弱い
    ['K', 'コウモリ', 7, 2, 3, 1],            # ふらふら
    ['O', 'オオウミウシ', 7, 3, 2, 4],        # 体当たり
    ['T', 'ツバメ', 5, 2, 3, 9],              # 速い
    ['W', 'ワラビー', 8, 5, 4, 9],            # 蹴ってくる
    ['S', '催眠術師', 16, 12, 6, 11],         # 寝てる。眠らせる
    ['P', 'ピューシャン', 9, 5, 4, 15],       # 矢を打つ
    ['F', 'ファンガス', 17, 6, 6, 8],         # 胞子で力を下げる
    ['G', 'グール', 10, 7, 4, 15],            # 増える
    ['M', 'ミイラ', 16, 16, 10, 19],          # 回復アイテムでダメージ
    ['G', 'ノーム', 20, 10, 0, 16],           # 金を盗む
    ['H', 'ハゲタカ', 27, 25, 10, 16],        # クチバシが痛い
    ['S', 'ソーサラー', 23, 15, 10, 16],      # 瞬間移動の杖を振る
    ['M', 'メタルヨテイチ', 3, 500, 30, 49],  # 回避性のレアモン
    ['O', 'おめん武者', 35, 40, 15, 26],      # 鎧の中は空洞だ
    ['A', 'アクアター', 30, 25, 0, 19],       # ガッポーン。盾が錆びるぞ
    ['D', 'どろぼう猫', 40, 20, 0, 17],       # アイテムを盗む
    ['G', 'ガーゴイル', 45, 50, 18, 27],      # 石像のふりをしている
    ['Y', '四人トリオ', 60, 10, 11, 3],       # 4人で固まって出現する
    ['S', '白い手', 72, 40, 7, 23],           # つかまると倒すまで動けない
    ['G', 'ゴーレム', 52, 180, 32, 27],       # 巨大な泥人形
    ['B', 'ボンプキン', 70, 30, 12, 23],      # 爆発する
    ['P', 'パペット', 36, 40, 13, 23],        # レベルを下げる
    ['Y', 'ゆうれい', 60, 150, 17, 27],       # 見えない。ふらふら
    ['M', 'ミミック', 50, 30, 24, 24],        # アイテム・階段に化ける
    ['T', 'トロール', 51, 380, 51, 21],       # 強い
    ['B', '化け狸', 80, 20, 9, 14],           # 別のモンスターに化ける
    ['D', '土偶', 70, 150, 17, 24],           # HP、ちから最大値を下げる
    ['D', 'デビルモンキー', 78, 600, 26, 25], # 二倍速
    ['M', 'マルスボース', 75, 750, 51, 29],   # 強い
    ['R', '竜', 100, 3000, 68, 30],           # テラ強い。火を吐く
  ]

  class << self
    def make_monster(name)
      row = SPECIES.find { |r| r[1] == name }
      fail "no such monster: #{name}" if row.nil?

      char, name, max_hp, strength, defense, exp = row
      return Monster.new(char, name, max_hp, strength, defense, exp)
    end
  end

  attr :char, :name, :max_hp, :strength, :defense, :exp

  def initialize(char, name, max_hp, strength, defense, exp)
    fail unless char =~ /\A[A-Z]\z/
    @char     = char
    @name     = name
    @max_hp   = max_hp
    @strength = strength
    @defense  = defense
    @exp      = exp
  end
end
