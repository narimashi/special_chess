extends Node

# チェスボードの定数
const BOARD_SIZE = 8
const SQUARE_SIZE = 80  # ピクセル単位

# 駒の種類
enum PieceType {PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING}

# プレイヤー
enum Player {WHITE, BLACK}

# 難易度
enum Difficulty {EASY, MEDIUM, HARD}

# 現在のゲーム設定
var current_difficulty = Difficulty.MEDIUM
var sound_enabled = true
var music_enabled = true

# 駒のテキスト表現
var piece_to_char = {
    PieceType.PAWN: "P",
    PieceType.ROOK: "R",
    PieceType.KNIGHT: "N",
    PieceType.BISHOP: "B",
    PieceType.QUEEN: "Q",
    PieceType.KING: "K"
}

# テキストから駒への変換
var char_to_piece = {
    "P": PieceType.PAWN,
    "R": PieceType.ROOK,
    "N": PieceType.KNIGHT,
    "B": PieceType.BISHOP,
    "Q": PieceType.QUEEN,
    "K": PieceType.KING
}

# プレイヤーのテキスト表現
func get_player_name(player):
    return "White" if player == Player.WHITE else "Black"

# 画面サイズ
var screen_size = Vector2(800, 900)  # 基本サイズ

# ゲーム状態
var game_in_progress = false

# 初期化
func _ready():
    # シード値の設定でランダム性を保証
    randomize()