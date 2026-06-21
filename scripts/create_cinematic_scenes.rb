# Load this file from SketchUp Ruby Console:
# load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
#
# It creates 13 camera scenes from the active model's bounding box.
# The scenes are intentionally generic and should be reviewed with a contact sheet.

SCENE_PREFIX = "AI Cinematic" unless defined?(SCENE_PREFIX)
REPLACE_EXISTING_AI_SCENES = false unless defined?(REPLACE_EXISTING_AI_SCENES)
SCENE_COUNT = 13 unless defined?(SCENE_COUNT)

model = Sketchup.active_model
raise "No active SketchUp model" unless model

view = model.active_view
bounds = model.bounds
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
radius = [diag * 0.95, width.abs, depth.abs, 12.m].max

ground_z = min.z
mid_z = min.z + height * 0.42
upper_z = min.z + height * 0.68

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

def set_camera(view, eye, target, focal_length = 28.mm)
  camera = Sketchup::Camera.new(eye, target, Z_AXIS)
  camera.perspective = true
  camera.focal_length = focal_length
  view.camera = camera
  view.zoom_extents
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
    eye: point_from(center, radius * 0.95, front_angle, ground_z + height * 0.38),
    target: target_from(center, 0, 0, mid_z),
    focal: 30.mm
  },
  {
    name: "02 草坪庭院低机位",
    eye: point_from(center, radius * 0.82, front_angle + 28, ground_z + height * 0.18),
    target: target_from(center, 0, 0, mid_z),
    focal: 26.mm
  },
  {
    name: "03 建筑正面展示",
    eye: point_from(center, radius * 1.05, front_angle, ground_z + height * 0.45),
    target: target_from(center, 0, 0, mid_z),
    focal: 35.mm
  },
  {
    name: "04 右前侧景观",
    eye: point_from(center, radius * 0.90, front_angle + 55, ground_z + height * 0.34),
    target: target_from(center, width * 0.10, depth * 0.08, mid_z),
    focal: 30.mm
  },
  {
    name: "05 左前侧景观",
    eye: point_from(center, radius * 0.90, front_angle - 55, ground_z + height * 0.34),
    target: target_from(center, -width * 0.10, -depth * 0.08, mid_z),
    focal: 30.mm
  },
  {
    name: "06 侧面体量关系",
    eye: point_from(center, radius * 0.92, front_angle + 90, ground_z + height * 0.40),
    target: target_from(center, 0, 0, mid_z),
    focal: 35.mm
  },
  {
    name: "07 背侧庭院关系",
    eye: point_from(center, radius * 0.92, front_angle + 180, ground_z + height * 0.38),
    target: target_from(center, 0, 0, mid_z),
    focal: 32.mm
  },
  {
    name: "08 高位鸟瞰总览",
    eye: point_from(center, radius * 0.95, front_angle + 35, ground_z + height * 1.65),
    target: target_from(center, 0, 0, mid_z),
    focal: 32.mm
  },
  {
    name: "09 屋顶与草坪关系",
    eye: point_from(center, radius * 0.70, front_angle - 130, ground_z + height * 1.25),
    target: target_from(center, 0, 0, upper_z),
    focal: 38.mm
  },
  {
    name: "10 景观入口近景",
    eye: point_from(center, radius * 0.50, front_angle + 18, ground_z + height * 0.20),
    target: target_from(center, width * 0.12, depth * 0.12, ground_z + height * 0.30),
    focal: 40.mm
  },
  {
    name: "11 材质立面近景",
    eye: point_from(center, radius * 0.48, front_angle - 20, ground_z + height * 0.32),
    target: target_from(center, -width * 0.10, 0, mid_z),
    focal: 45.mm
  },
  {
    name: "12 黄昏主视觉",
    eye: point_from(center, radius * 0.90, front_angle + 15, ground_z + height * 0.33),
    target: target_from(center, 0, 0, mid_z),
    focal: 32.mm,
    shadow_time: Time.local(Time.now.year, 10, 15, 17, 20, 0).to_i
  },
  {
    name: "13 作品集封面广角",
    eye: point_from(center, radius * 1.10, front_angle - 25, ground_z + height * 0.45),
    target: target_from(center, 0, 0, mid_z),
    focal: 24.mm
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
