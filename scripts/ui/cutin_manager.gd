extends CanvasLayer

# カットインアニメーション管理

# カットインアニメーションのパス
var cutin_data = {
	"castling": {
		"image": "res://assets/cutins/castling.png",
		"sound": "res://assets/sounds/castling.mp3",
		"text": "キャスリング！"
	},
	"fork": {
		"image": "res://assets/cutins/fork.png",
		"sound": "res://assets/sounds/tactic.mp3",
		"text": "フォーク！"
	},
	"pin": {
		"image": "res://assets/cutins/pin.png",
		"sound": "res://assets/sounds/tactic.mp3",
		"text": "ピン！"
	},
	"discovered_attack": {
		"image": "res://assets/cutins/discovered_attack.png",
		"sound": "res://assets/sounds/tactic.mp3",
		"text": "ディスカバードアタック！"
	},
	"check": {
		"image": "res://assets/cutins/check.png",
		"sound": "res://assets/sounds/check.mp3",
		"text": "チェック！"
	},
	"checkmate": {
		"image": "res://assets/cutins/checkmate.png",
		"sound": "res://assets/sounds/checkmate.mp3",
		"text": "チェックメイト！"
	}
}

var is_playing: bool = false

@onready var animation_player = $AnimationPlayer
@onready var cutin_sprite = $CutInContainer/CutInSprite
@onready var cutin_label = $CutInContainer/CutInLabel
@onready var sound_player = $SoundPlayer

func _ready() -> void:
	# 初期状態では非表示
	$CutInContainer.visible = false
	
	# ラベルにシステムフォントを設定
	if cutin_label:
		cutin_label.add_theme_font_size_override("font_size", 32)
	
	# アニメーションの作成
	if not animation_player.has_animation("cutin_animation"):
		_create_animation()

func _create_animation() -> void:
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, "CutInContainer:modulate")
	animation.track_insert_key(track_idx, 0.0, Color(1, 1, 1, 0))
	animation.track_insert_key(track_idx, 0.5, Color(1, 1, 1, 1))
	animation.track_insert_key(track_idx, 2.0, Color(1, 1, 1, 1))
	animation.track_insert_key(track_idx, 2.5, Color(1, 1, 1, 0))
	animation.length = 3.0
	
	var animation_library = AnimationLibrary.new()
	animation_library.add_animation("cutin_animation", animation)
	animation_player.add_animation_library("", animation_library)

func play_cutin(tactic_name: String) -> void:
	# 無効化されている場合は何もしない
	if not Globals.sound_enabled:
		return
	
	# 再生中なら待機（同時に複数のカットインは表示しない）
	if is_playing:
		await animation_player.animation_finished
	
	# 該当する戦術がなければ何もしない
	if not cutin_data.has(tactic_name):
		return
	
	is_playing = true
	
	# カットイン画像とテキストの設定
	cutin_sprite.texture = null
	
	# 画像をロード（あれば）
	var image_path = cutin_data[tactic_name].get("image", "")
	if ResourceLoader.exists(image_path):
		cutin_sprite.texture = load(image_path)
	
	# テキストを設定
	cutin_label.text = cutin_data[tactic_name].get("text", tactic_name.capitalize())
	
	# コンテナを表示
	$CutInContainer.visible = true
	$CutInContainer.modulate = Color(1, 1, 1, 1) # 完全に不透明に設定
	
	# サウンドの再生
	if Globals.sound_enabled and sound_player:
		var sound_path = cutin_data[tactic_name].get("sound", "")
		if ResourceLoader.exists(sound_path):
			sound_player.stream = load(sound_path)
			sound_player.play()
	
	# アニメーションの再生
	if animation_player and animation_player.has_animation("cutin_animation"):
		animation_player.play("cutin_animation")
		# アニメーション完了を待機
		await animation_player.animation_finished
	else:
		# アニメーションがない場合は3秒待って手動で非表示
		await get_tree().create_timer(3.0).timeout
	
	# 非表示に戻す
	$CutInContainer.visible = false
	is_playing = false