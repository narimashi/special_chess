extends Control

# ポーンの昇格選択ダイアログ

signal promotion_selected(promotion_type)

var piece
var target_pos
var player_color

func _ready():
    # 初期状態では非表示
    visible = false
    
    # ボタンにシグナルを接続
    $VBoxContainer/HBoxContainer/QueenButton.connect("pressed", self, "_on_queen_selected")
    $VBoxContainer/HBoxContainer/RookButton.connect("pressed", self, "_on_rook_selected")
    $VBoxContainer/HBoxContainer/BishopButton.connect("pressed", self, "_on_bishop_selected")
    $VBoxContainer/HBoxContainer/KnightButton.connect("pressed", self, "_on_knight_selected")

func show_for_piece(target_piece, to_position):
    piece = target_piece
    target_pos = to_position
    player_color = piece.player
    
    # 画像を適切なプレイヤーカラーに設定
    var color_prefix = "white" if player_color == Globals.Player.WHITE else "black"
    
    $VBoxContainer/HBoxContainer/QueenButton.icon = load("res://assets/pieces/" + color_prefix + "_queen.png")
    $VBoxContainer/HBoxContainer/RookButton.icon = load("res://assets/pieces/" + color_prefix + "_rook.png")
    $VBoxContainer/HBoxContainer/BishopButton.icon = load("res://assets/pieces/" + color_prefix + "_bishop.png")
    $VBoxContainer/HBoxContainer/KnightButton.icon = load("res://assets/pieces/" + color_prefix + "_knight.png")
    
    # ダイアログを表示
    visible = true
    
    # モーダルモードに設定（ダイアログ外のクリックを無効化）
    set_process_input(true)

func _on_queen_selected():
    _handle_selection(Globals.PieceType.QUEEN)

func _on_rook_selected():
    _handle_selection(Globals.PieceType.ROOK)

func _on_bishop_selected():
    _handle_selection(Globals.PieceType.BISHOP)

func _on_knight_selected():
    _handle_selection(Globals.PieceType.KNIGHT)

func _handle_selection(promotion_type):
    # 非表示に戻す
    visible = false
    set_process_input(false)
    
    # 選択結果を通知
    emit_signal("promotion_selected", promotion_type)

func _input(event):
    # モーダルモード中は他のクリックを無視
    if visible and event is InputEventMouseButton and event.pressed:
        var rect = get_rect()
        if not rect.has_point(event.position):
            get_tree().set_input_as_handled()