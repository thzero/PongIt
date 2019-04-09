extends Node

const CHAT_HISTORY_LENGTH = 10

const DEFAULT_SERVER_PORT = 8910 # some random number, pick your port properly
const DEFAULT_SERVER_ADDRESS = '127.0.0.1'
const DEFAULT_SERVER_NAME = 'Server'

const MAX_PLAYERS = 2
const MIN_PLAYERS = 2

const PATH_CHAT = "res://chat.gd"
const PATH_CHAT_TYPES = "res://chat/types.gd"
const PATH_GAMESTATE_CHAT = "res://networking/chat.gd"
const PATH_GAMESTATE_MONITOR = "res://networking/monitor.gd"
const PATH_GAMESTATE_PLAYER_SELECTOR = "res://networking/player_selector.gd"
const PATH_GAMESTATE_VALIDATOR = "res://networking/validator.gd"
const PATH_LOBBY = "res://lobby/lobby.tscn"

const PING_ENABLED = true
const PING_DELAY = 1.0 / 60
const PRING_RTT_SAMPLE = 10

const REGEX_PLAYER_NAME = "[\\w-]"
const REGEX_PLAYER_NAME_LENGTH = "{3,25}"

const VERSION = '0.1'