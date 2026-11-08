extends Control

const INK := Color("#171d1b")
const STONE := Color("#a19883")
const GOLD := Color("#ffd183")
const MOSS := Color("#798775")
var position_on_map := Vector3.ZERO
var destination := Vector3.ZERO
var has_destination := false
var valley := false


func update_map(player: Vector3, target: Vector3, show_target: bool, show_valley: bool) -> void:
	position_on_map = player
	destination = target
	has_destination = show_target
	valley = show_valley
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) * 0.48
	draw_circle(center, radius, INK)
	draw_arc(center, radius, 0.0, TAU, 64, STONE, 1.2, true)
	draw_arc(center, radius - 5.0, 0.0, TAU, 64, Color("#74654e"), 1.0, true)
	var zoom := 1.22 if valley else 2.28
	var origin := center + Vector2(0, -28 if valley else 3)
	var half := 22.0 * zoom
	var castle := Rect2(origin - Vector2.ONE * half, Vector2.ONE * half * 2)
	draw_rect(castle, Color("#39473a"))
	draw_rect(castle, MOSS, false, 1.0)
	draw_line(origin + Vector2(0, -half * 0.78), origin + Vector2(0, half), MOSS, 1.0, true)
	for side in [-1.0, 1.0]:
		for edge in [-1.0, 1.0]:
			draw_circle(origin + Vector2(side, edge) * half, 3.6, STONE)
	if valley:
		draw_line(origin + Vector2(-64, 29.9 * zoom), origin + Vector2(64, 29.9 * zoom),
			Color("#578a83"), 3.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, center + Vector2(-15, -radius + 19), "Nord", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, STONE)
	if has_destination:
		var goal := _map_point(destination, origin, zoom, center, radius)
		draw_set_transform(goal, PI / 4)
		draw_rect(Rect2(Vector2(-4, -4), Vector2(8, 8)), GOLD)
		draw_set_transform(Vector2.ZERO)
	var player_dot := _map_point(position_on_map, origin, zoom, center, radius)
	draw_circle(player_dot, 5.4, INK)
	draw_circle(player_dot, 3.8, Color("#faf4de"))


func _map_point(point: Vector3, origin: Vector2, zoom: float, center: Vector2, radius: float) -> Vector2:
	var raw := origin + Vector2(point.x, point.z) * zoom
	return center + (raw - center).limit_length(radius - 12.0)
