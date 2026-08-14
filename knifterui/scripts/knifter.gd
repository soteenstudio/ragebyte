@tool
extends PanelContainer

@onready var details_page = $DetailsPage
@onready var browser_page = $BrowserPage

# Ambil referensi button-nya (sesuaikan path-nya ya)
@onready var btn_details = $HBoxContainer/DetailsButton 
@onready var btn_browser = $HBoxContainer/BrowserButton

@onready var http_request = $BrowserPage/HTTPRequest

func _ready() -> void:
	print("KnifterUI: System Ready!")
	
	# Konekin signal via code biar anti-ghosting
	if not btn_details.is_connected("pressed", _details_button):
		btn_details.pressed.connect(_details_button)
	if not btn_browser.is_connected("pressed", _browser_button):
		btn_browser.pressed.connect(_browser_button)
		
	_browser_button() # Default view
	
	http_request.request_completed.connect(_on_request_completed)
	
	# Contoh manggil URL (bisa HTML atau JSON API)
	var error = http_request.request("https://github.com/zen")
	if error != OK:
		push_error("Waduh, gagal kirim request!")

func _details_button() -> void:
	if details_page and browser_page:
		details_page.visible = true
		browser_page.visible = false

func _browser_button() -> void:
	if details_page and browser_page:
		details_page.visible = false
		browser_page.visible = true

# Fungsi ini jalan pas data udah selese di-download
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var data = body.get_string_from_utf8()
		$BrowserPage/WebsiteBox.text = parse_html_to_bbcode(data)
	else:
		print("Gagal ngambil data. Kode error: ", response_code)

func parse_html_to_bbcode(html_text: String) -> String:
	var bbcode = html_text
	
	# 1. Hapus tag yang gak penting kayak <div>, <span>, <body>, dll
	var unwanted_tags = ["div", "span", "body", "html", "p", "header", "footer"]
	for tag in unwanted_tags:
		var re_open = RegEx.new()
		re_open.compile("<" + tag + "[^>]*>")
		bbcode = re_open.sub(bbcode, "", true)
		
		var re_close = RegEx.new()
		re_close.compile("</" + tag + ">")
		bbcode = re_close.sub(bbcode, "", true)

	# 2. Ganti tag Bold, Italic, Underline
	bbcode = bbcode.replace("<b>", "[b]").replace("</b>", "[/b]")
	bbcode = bbcode.replace("<strong>", "[b]").replace("</strong>", "[/b]")
	bbcode = bbcode.replace("<i>", "[i]").replace("</i>", "[/i]")
	bbcode = bbcode.replace("<em>", "[i]").replace("</em>", "[/i]")
	bbcode = bbcode.replace("<u>", "[u]").replace("</u>", "[/u]")

	# 3. Ganti Line Breaks (<br>)
	bbcode = bbcode.replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n")

	# 4. Parser Link (<a> tag) - Ini agak tricky pake RegEx
	var re_link = RegEx.new()
	# Mencari <a href="URL">TEXT</a>
	re_link.compile('<a [^>]*href="([^"]+)"[^>]*>(.*?)</a>')
	bbcode = re_link.sub(bbcode, "[url=$1]$2[/url]", true)

	return bbcode
