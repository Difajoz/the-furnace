extends Node

func _ready() -> void:
	print('Testing viewport capture capability...')
	var vp = get_viewport()
	print('Viewport size: ', vp.get_visible_rect().size)
	await get_tree().process_frame
	await get_tree().process_frame
	var img = vp.get_texture().get_image()
	if img:
		print('Got image! Size: ', img.get_size(), ' Format: ', img.get_format())
		var err = img.save_png('res://test_vp_capture.png')
		print('Save PNG result: ', err)
	else:
		print('No image from viewport!')
	get_tree().quit(0)
