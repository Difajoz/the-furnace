extends Node

func _ready() -> void:
	print('Loading main scene...')
	var main_res = load('res://scenes/main.tscn')
	var main = main_res.instantiate()
	add_child(main)
	
	# Wait for rendering to start
	for i in range(15):
		await get_tree().process_frame
		
	var vp = get_viewport()
	var img = vp.get_texture().get_image()
	if img:
		print('Captured viewport! Size: ', img.get_size())
		DirAccess.make_dir_absolute('res://media')
		img.save_png('res://media/test_menu.png')
		print('Saved test_menu.png successfully!')
	else:
		print('Failed to get viewport image!')
	get_tree().quit(0)
