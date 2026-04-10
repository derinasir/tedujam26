extends Control

@onready var canvas: TextureRect = $DrawingCanvas
@onready var brush_size_slider: HSlider = $UI/SidePanel/BrushSize/Slider
@onready var brush_size_label: Label = $UI/SidePanel/BrushSize/Label
@onready var opacity_slider: HSlider = $UI/SidePanel/Opacity/Slider
@onready var opacity_label: Label = $UI/SidePanel/Opacity/Label
@onready var color_picker: ColorPickerButton = $UI/SidePanel/ColorPicker
@onready var erase_btn: Button = $UI/SidePanel/EraseBtn
@onready var clear_btn: Button = $UI/SidePanel/ClearBtn
@onready var save_btn: Button = $UI/SidePanel/SaveBtn
@onready var round_btn: Button = $UI/SidePanel/BrushTypes/RoundBtn
@onready var square_btn: Button = $UI/SidePanel/BrushTypes/SquareBtn
@onready var spray_btn: Button = $UI/SidePanel/BrushTypes/SprayBtn

func _ready() -> void:
	# Brush size
	brush_size_slider.min_value = 1
	brush_size_slider.max_value = 80
	brush_size_slider.value = 16
	brush_size_slider.value_changed.connect(_on_brush_size_changed)
	_on_brush_size_changed(16)

	# Opacity
	opacity_slider.min_value = 0.05
	opacity_slider.max_value = 1.0
	opacity_slider.step = 0.05
	opacity_slider.value = 1.0
	opacity_slider.value_changed.connect(_on_opacity_changed)
	_on_opacity_changed(1.0)

	# Color
	color_picker.color = Color.BLACK
	color_picker.color_changed.connect(_on_color_changed)

	# Buttons
	erase_btn.toggle_mode = true
	erase_btn.toggled.connect(_on_erase_toggled)

	clear_btn.pressed.connect(_on_clear_pressed)
	save_btn.pressed.connect(_on_save_pressed)

	round_btn.pressed.connect(func(): canvas.set_brush_type("round"))
	square_btn.pressed.connect(func(): canvas.set_brush_type("square"))
	spray_btn.pressed.connect(func(): canvas.set_brush_type("spray"))

func _on_brush_size_changed(value: float) -> void:
	canvas.set_brush_size(int(value))
	brush_size_label.text = "Size: %d" % int(value)

func _on_opacity_changed(value: float) -> void:
	canvas.set_opacity(value)
	opacity_label.text = "Opacity: %d%%" % int(value * 100)

func _on_color_changed(color: Color) -> void:
	canvas.set_brush_color(color)
	if erase_btn.button_pressed:
		erase_btn.set_pressed(false)
		canvas.set_erasing(false)

func _on_erase_toggled(pressed: bool) -> void:
	canvas.set_erasing(pressed)
	erase_btn.text = "Erasing ON" if pressed else "Eraser"

func _on_clear_pressed() -> void:
	canvas.clear_canvas()

func _on_save_pressed() -> void:
	canvas.save_canvas("user://my_drawing.png")
	# Show feedback
	save_btn.text = "Saved!"
	await get_tree().create_timer(1.5).timeout
	save_btn.text = "Save PNG"
