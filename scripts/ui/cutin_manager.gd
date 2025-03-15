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
	if cutin_data[tactic_name].has("image"):
		var image_path = cutin_data[tactic_name]["image"]
		if FileAccess.file_exists(image_path):
			var texture = load(image_path)
			if texture:
				cutin_sprite.texture = texture
	
	# テキストを設定
	cutin_label.text = cutin_data[tactic_name]["text"]
	
	# システムフォントを確保
	if cutin_label:
		var theme = cutin_label.get_theme() if cutin_label.get_theme() else Theme.new()
		cutin_label.theme = theme
	
	# コンテナを表示
	$CutInContainer.visible = true
	
	# サウンドの再生
	if Globals.sound_enabled and cutin_data[tactic_name].has("sound"):
		var sound_path = cutin_data[tactic_name]["sound"]
		if FileAccess.file_exists(sound_path):
			var stream = load(sound_path)
			if stream:
				sound_player.stream = stream
				sound_player.play()
	
	# アニメーションの再生
	if animation_player.has_animation("cutin_animation"):
		animation_player.play("cutin_animation")
		# アニメーション完了を待機
		await animation_player.animation_finished
	else:
		# アニメーションがない場合は手動でフェードインアウト
		$CutInContainer.modulate.a = 0
		var tween = create_tween()
		tween.tween_property($CutInContainer, "modulate:a", 1.0, 0.5)
		tween.tween_interval(1.0)
		tween.tween_property($CutInContainer, "modulate:a", 0.0, 0.5)
		await tween.finished
	
	# 非表示に戻す
	$CutInContainer.visible = false
	is_playing = false