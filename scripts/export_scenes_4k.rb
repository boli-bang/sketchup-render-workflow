# Load this file from SketchUp Ruby Console:
# load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"

WIDTH = 3840 unless defined?(WIDTH)
HEIGHT = 2160 unless defined?(HEIGHT)
START_INDEX = 1 unless defined?(START_INDEX)
END_INDEX = nil unless defined?(END_INDEX)

model = Sketchup.active_model
raise "No active SketchUp model" unless model

pages = model.pages.to_a
raise "This model has no scenes/pages" if pages.empty?

model_path = model.path
base_dir = if model_path && !model_path.empty?
  File.dirname(model_path)
else
  Dir.home
end

model_name = if model_path && !model_path.empty?
  File.basename(model_path, File.extname(model_path))
else
  "untitled_sketchup_model"
end

safe_model_name = model_name.gsub(/[\/\\:*?"<>|]/, "_")
out_dir = File.join(base_dir, "#{safe_model_name}_scene_exports_4k")
Dir.mkdir(out_dir) unless Dir.exist?(out_dir)

finish = END_INDEX || pages.length
selected = pages.each_with_index.select { |_page, i| (i + 1) >= START_INDEX && (i + 1) <= finish }
raise "No scenes selected" if selected.empty?

log_path = File.join(out_dir, "#{safe_model_name}_scene_export_log.txt")
File.open(log_path, "a") do |log|
  log.puts "Export started: #{Time.now}"
  log.puts "Model: #{model_path}"
  log.puts "Size: #{WIDTH}x#{HEIGHT}"
  selected.each do |page, zero_index|
    one_index = zero_index + 1
    model.pages.selected_page = page
    model.active_view.refresh
    sleep 0.25
    safe_scene = page.name.gsub(/[\/\\:*?"<>|]/, "_")
    filename = format("%s_%02d_%s.png", safe_model_name, one_index, safe_scene)
    output = File.join(out_dir, filename)
    options = {
      filename: output,
      width: WIDTH,
      height: HEIGHT,
      antialias: true,
      transparent: false,
      compression: 0.9
    }
    result = model.active_view.write_image(options)
    log.puts "scene #{one_index}: #{page.name} -> #{output} result=#{result} exists=#{File.exist?(output)}"
  end
  log.puts "Export finished: #{Time.now}"
end

done_path = File.join(out_dir, "#{safe_model_name}_导出完成.txt")
File.write(done_path, "Exported #{selected.length} scenes at #{Time.now}\nOutput: #{out_dir}\n")
UI.messagebox("Exported #{selected.length} scenes to:\n#{out_dir}")
