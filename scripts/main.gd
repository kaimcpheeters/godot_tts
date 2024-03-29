extends Node
signal tts_generated_speech

const ELEVENLABS_API_KEY : String = ""
const ELEVENLABS_URL : String = "https://api.elevenlabs.io/v1/text-to-speech/"
const MALE_VOICE_CODE : String = "N2lVS1w4EtoT3dr4eOWO"
const FEMALE_VOICE_CODE : String = "XB0fDUnXU5powFXDhCwa"
const TTS_AUDIO_PATH = "user://tts_audio.mp3"

var use_stream_mode : bool = false
var audio_stream_player : AudioStreamPlayer
var audio_stream : AudioStream
var http_request : HTTPRequest
var endpoint : String
var headers : PoolStringArray

func _ready():
	_initialize()
	var text = "Luke, I am your father"
	call_tts(text)


func _initialize():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.set_download_file(TTS_AUDIO_PATH)
	http_request.connect("request_completed", self, "_on_request_completed")
	
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	
func call_tts(text, voice_code=MALE_VOICE_CODE):
	print(text)
	_call_tts_elevenlabs(text, voice_code)

func _call_tts_elevenlabs(text, voice_code):
	if use_stream_mode:
		endpoint = ELEVENLABS_URL + voice_code + "/stream"
		audio_stream = AudioStreamSample.new()
		headers = PoolStringArray(["accept: */*", "xi-api-key: " + ELEVENLABS_API_KEY, "Content-Type: application/json"])
	else:
		endpoint = ELEVENLABS_URL + voice_code
		audio_stream = AudioStreamMP3.new()
		headers = PoolStringArray(["accept: audio/mpeg", "xi-api-key: " + ELEVENLABS_API_KEY, "Content-Type: application/json"])
	var body = JSON.print({
		"text": text,
		"voice_settings": {"stability": 0, "similarity_boost": 0}
	})
	var error = http_request.request(endpoint, headers, true, HTTPClient.METHOD_POST, body)
	
	if error != OK:
		push_error("Something Went Wrong!")
		print(error)
		
func _on_request_completed(result, response_code, headers, body):
	# Should recieve 200 if all is fine; if not print code
	if response_code != 200:
		print("There was an error, response code:" + str(response_code))
		print(result)
		print(headers)
		print(body)
		return
		
	var audio_file_from_eleven = body
	
	var file = File.new()
	var err = file.open(TTS_AUDIO_PATH, File.READ)
	var bytes = file.get_buffer(file.get_len())
	audio_stream.data = bytes 
	audio_stream_player.set_stream(audio_stream)
	audio_stream_player.play()
	
	emit_signal("tts_generated_speech")
