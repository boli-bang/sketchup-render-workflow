# Load this file from SketchUp Ruby Console:
# load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
#
# It creates up to 13 camera scenes from visible active-model bounds.
# Primary exterior scenes use two-point architectural perspective so verticals stay upright.
# The scenes are still candidates: export a few, review, then keep or tune weak angles.

SCENE_PREFIX = "AI Cinematic" unless defined?(SCENE_PREFIX)
REPLACE_EXISTING_AI_SCENES = false unless defined?(REPLACE_EXISTING_AI_SCENES)
SCENE_COUNT = 13 unless defined?(SCENE_COUNT)

model = Sketchup.active_model
raise "No active SketchUp model" unless model

view = model.active_view
def entity_visible?(entity)
  return false if entity.hidden?
  layer = entity.respond_to?(:layer) ? entity.layer : nil
  return false if layer && layer.respond_to?(:visible?) && !layer.visible?
  true
rescue
  true
end

def useful_bounds?(bounds)
  return false unless bounds && bounds.valid?
  width = (bounds.max.x - bounds.min.x).abs
  depth = (bounds.max.y - bounds.min.y).abs
  height = (bounds.max.z - bounds.min.z).abs
  [width, depth, height].max > 1.inch
end

def add_bounds(target, source)
  target.add(source.min)
  target.add(source.max)
end

bounds = Geom::BoundingBox.new
model.entities.each do |entity|
  next unless entity_visible?(entity)
  next unless entity.respond_to?(:bounds)
  entity_bounds = entity.bounds
  next unless useful_bounds?(entity_bounds)
  add_bounds(bounds, entity_bounds)
end
bounds = model.bounds unless bounds.valid?
raise "Model bounds are empty" unless bounds && bounds.valid?

min = bounds.min
max = bounds.max
center = Geom::Point3d.new(
  (min.x + max.x) / 2.0,
  (min.y + max.y) / 2.0,
  (min.z + max.z) / 2.0
)

width = max.x - min.x
depth = max.y - min.y
height = [max.z - min.z, 1.m].max
diag = Math.sqrt(width * width + depth * depth + height * height)
span = [width.abs, depth.abs].max
radius = [span * 0.58, height * 3.0, 8.m].max

ground_z = min.z
mid_z = min.z + height * 0.42
upper_z = min.z + height * 0.68
two_point_z = min.z + height * 0.46
low_two_point_z = min.z + height * 0.34

def point_from(center, radius, angle_deg, z)
  angle = angle_deg.degrees
  Geom::Point3d.new(
    center.x + Math.cos(angle) * radius,
    center.y + Math.sin(angle) * radius,
    z
  )
end

def target_from(center, x_offset, y_offset, z)
  Geom::Point3d.new(center.x + x_offset, center.y + y_offset, z)
end

def set_camera(view, eye, target, focal_length = 28)
  camera = Sketchup::Camera.new(eye, target, Z_AXIS)
  camera.perspective = true
  camera.focal_length = focal_length
  view.camera = camera
  view.camera = camera
  view.refresh
end

if REPLACE_EXISTING_AI_SCENES
  model.pages.to_a.each do |page|
    model.pages.erase(page) if page.name.start_with?(SCENE_PREFIX)
  end
end

shadow = model.shadow_info
shadow["DisplayShadows"] = true
shadow["UseSunForAllShading"] = true
shadow["Light"] = 80
shadow["Dark"] = 45
shadow["ShadowTime_time_t"] = Time.local(Time.now.year, 9, 21, 15, 30, 0).to_i

major = width >= depth ? :x : :y
front_angle = major == :x ? -35 : -125

scene_count = [[SCENE_COUNT.to_i, 1].max, 13].min

scenes = [
  {
    name: "01 主入口45度",
    eye: point_from(center, radius * 0.78, front_angle, two_point_z),
    target: target_from(center, 0, 0, two_point_z),
    focal: 55
  },
  {
    name: "02 草坪庭院低机位",
    eye: point_from(center, radius * 0.62, front_angle + 28, low_two_point_z),
    target: target_from(center, 0, 0, low_two_point_z),
    focal: 42
  },
  {
    name: "03 建筑正面展示",
    eye: point_from(center, radius * 0.86, front_angle, two_point_z),
    target: target_from(center, 0, 0, two_point_z),
    focal: 60
  },
  {
    name: "04 右前侧景观",
    eye: point_from(center, radius * 0.70, front_angle + 55, two_point_z),
    target: target_from(center, width * 0.10, depth * 0.08, two_point_z),
    focal: 52
  },
  {
    name: "05 左前侧景观",
    eye: point_from(center, radius * 0.70, front_angle - 55, two_point_z),
    target: target_from(center, -width * 0.10, -depth * 0.08, two_point_z),
    focal: 52
  },
  {
    name: "06 侧面体量关系",
    eye: point_from(center, radius * 0.76, front_angle + 90, two_point_z),
    target: target_from(center, 0, 0, two_point_z),
    focal: 55
  },
  {
    name: "07 背侧庭院关系",
    eye: point_from(center, radius * 0.76, front_angle + 180, two_point_z),
    target: target_from(center, 0, 0, two_point_z),
    focal: 52
  },
  {
    name: "08 高位鸟瞰总览",
    eye: point_from(center, radius * 0.96, front_angle + 35, ground_z + height * 1.55),
    target: target_from(center, 0, 0, mid_z),
    focal: 45
  },
  {
    name: "09 屋顶与草坪关系",
    eye: point_from(center, radius * 0.66, front_angle - 130, ground_z + height * 1.05),
    target: target_from(center, 0, 0, upper_z),
    focal: 55
  },
  {
    name: "10 景观入口近景",
    eye: point_from(center, radius * 0.38, front_angle + 18, low_two_point_z),
    target: target_from(center, width * 0.12, depth * 0.12, low_two_point_z),
    focal: 65
  },
  {
    name: "11 材质立面近景",
    eye: point_from(center, radius * 0.36, front_angle - 20, low_two_point_z),
    target: target_from(center, -width * 0.10, 0, low_two_point_z),
    focal: 70
  },
  {
    name: "12 黄昏主视觉",
    eye: point_from(center, radius * 0.72, front_angle + 15, two_point_z),
    target: target_from(center, 0, 0, two_point_z),
    focal: 52,
    shadow_time: Time.local(Time.now.year, 10, 15, 17, 20, 0).to_i
  },
  {
    name: "13 作品集封面广角",
    eye: point_from(center, radius * 0.92, front_angle - 25, two_point_z),
    target: target_from(center, 0, 0, two_point_z),
    focal: 38
  }
]

model.start_operation("Create AI cinematic scenes", true)
created = []
scenes.first(scene_count).each_with_index do |scene, index|
  shadow["ShadowTime_time_t"] = scene[:shadow_time] if scene[:shadow_time]
  set_camera(view, scene[:eye], scene[:target], scene[:focal])
  page_name = "#{SCENE_PREFIX} #{scene[:name]}"
  existing = model.pages.to_a.find { |page| page.name == page_name }
  page = existing || model.pages.add(page_name)
  page.update if page.respond_to?(:update)
  created << page.name
end
model.commit_operation

UI.messagebox("Created #{created.length} cinematic scenes:\n\n#{created.join("\n")}\n\nReview them before export.")
