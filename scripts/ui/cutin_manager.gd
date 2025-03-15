extends CanvasLayer

# カットインアニメーション管理

# カットインアニメーションのパス
var cutin_data = {
    "castling": {
        "image": "res://assets/cutins/castling.png",
        "sound": "res://assets/sounds/castling.wav",
        "text": "キャスリング！"
    },
    "fork": {
        "image": "res://assets/cutins/fork.png",
        "sound": "res://assets/sounds/tactic.wav",
        "text": "フォーク！"
    },
    "pin": {
        "image": "res://assets/cutins/pin.png",
        "sound": "res://assets/sounds/tactic.wav",
        "text": "ピン！"
    },
    "discovered_attack": {
        "image": "res://assets/cutins/discovered_attack.png",
        "sound": "res://assets/sounds/tactic.wav",
        "text": "ディスカバードアタック！"
    },
    "check": {
        "image": "res://assets/cutins/check.png",
        "sound": "res://assets/sounds/check.wav",
        "text": "チェック！"
    },
    "checkmate": {
        "image": "res://assets/cutins/checkmate.png",
        "sound": "res://assets/sounds/checkmate.wav",
        "text": "チェックメイト！"
    }
}

var is_playing = false

onready var animation_player = $AnimationPlayer
onready var cutin_sprite = $CutInContainer/CutInSprite
onready var cutin_label = $CutInContainer/CutInLabel
onready var sound_player = $SoundPlayer

func _ready():
    # 初期状態では非表示
    $CutInContainer.visible = false

func play_cutin(tactic_name):
    # 無効化されている場合は何もしない
    if not Globals.sound_enabled:
        return
    
    # 再生中なら待機（同時に複数のカットインは表示しない）
    if is_playing:
        yield(animation_player, "animation_finished")
    
    # 該当する戦術がなければ何もしない
    if not cutin_data.has(tactic_name):
        return
    
    is_playing = true
    
    # カットイン画像とテキストの設定
    var texture = load(cutin_data[tactic_name]["image"])
    cutin_sprite.texture = texture
    cutin_label.text = cutin_data[tactic_name]["text"]
    
    # コンテナを表示
    $CutInContainer.visible = true
    
    # サウンドの再生
    if Globals.sound_enabled:
        sound_player.stream = load(cutin_data[tactic_name]["sound"])
        sound_player.play()
    
    # アニメーションの再生
    animation_player.play("cutin_animation")
    
    # アニメーション完了を待機
    yield(animation_player, "animation_finished")
    
    # 非表示に戻す
    $CutInContainer.visible = false
    is_playing = false