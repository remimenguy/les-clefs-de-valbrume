extends RefCounted

const Progress = preload("res://scripts/progression.gd")
const PATH := "user://valbrume.json"


static func load_into(progress: Progress, path: String = PATH) -> void:
	if not _restore_from(path, progress):
		_restore_from(path + ".bak", progress)


static func write(progress: Progress, path: String = PATH) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(progress.snapshot()))
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written:
		return false
	var absolute := ProjectSettings.globalize_path(path)
	var previous: Progress = progress.get_script().new()
	if _restore_from(path, previous):
		if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(absolute + ".tmp", absolute) == OK


static func archive(progress: Progress, path: String = PATH) -> bool:
	var name := path.get_basename() + "-archive-%d-%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	return write(progress, name)


static func _restore_from(path: String, progress: Progress) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(path)) == OK and progress.restore(parser.data)
