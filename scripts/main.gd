extends Node
signal tts_generated_speech

const ELEVENLABS_API_KEY : String = "907bc085fbd00d0576f7fea0fa8748fc"
const MALE_VOICE_CODE : String = "N2lVS1w4EtoT3dr4eOWO"
const FEMALE_VOICE_CODE : String = "XB0fDUnXU5powFXDhCwa"
const ENDPOINT : String = "https://api.elevenlabs.io/v1/text-to-speech/"
const TTS_AUDIO_PATH = "user://tts_audio.mp3"

var character_code : String = MALE_VOICE_CODE
var use_stream_mode : bool = false
var audio_stream_player : AudioStreamPlayer
var audio_stream : AudioStream

var endpoint : String
var headers : PoolStringArray
var accept: String
var http_request : HTTPRequest

func _initialize():
	# Create httprequest node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.set_download_file(TTS_AUDIO_PATH)
	http_request.connect("request_completed", self, "_on_request_completed")
	
	# Create audio player node for speech playback
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	
	# Endpoint and headers change depending on if using stream mode
	if use_stream_mode == true:
		endpoint = ENDPOINT + character_code + "/stream"
		audio_stream = AudioStreamSample.new()
		accept = "accept: */*"
		headers = PoolStringArray([accept, "xi-api-key: " + ELEVENLABS_API_KEY, "Content-Type: application/json"])
	else:
		endpoint = ENDPOINT + character_code
		audio_stream = AudioStreamMP3.new()
		accept = "accept: audio/mpeg"
		headers = PoolStringArray([accept, "xi-api-key: " + ELEVENLABS_API_KEY, "Content-Type: application/json"])



func _call_elevenlabs(text):
	print("calling Eleven Labs TTS")
	var body = JSON.print({
		"text": text,
		"voice_settings": {"stability": 0, "similarity_boost": 0}
	})
	
	# Now call Eleven Labs
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

func _ready():
	_initialize()
	var text = "Luke, I am your father"
	print(text)
	_call_elevenlabs(text)
