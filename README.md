# SketchUp Render Workflow Skill

由 **镑的影像** 分享开发。

这是一个面向 Codex 的可迭代工作流 skill，用来把 SketchUp 建筑模型从 `.skp` 场景导出，到 AI 效果图生成提示词，再到最终图片整理命名，串成一套可以重复使用、持续改进的流程。

English documentation is included below for international users.

## 适合做什么

- 打开或接管已经打开的 SketchUp 模型
- 将 SketchUp 场景批量导出为 4K PNG 参考图
- 基于参考图生成高还原度建筑效果图提示词
- 当模型缺少园林、室内或软装时，先审计缺失项，再生成可确认的设计补全方向
- 检查 AI 生成图是否混入旧图、重复图或顺序错误
- 将最终效果图统一重命名为 `项目_AI效果图_01.png` 这类格式
- 把重复版本移动到 `_重复备份`，不误删原图

## 安装

把本仓库放到 Codex 的 skills 目录：

```bash
mkdir -p ~/.codex/skills
git clone <this-repo-url> ~/.codex/skills/sketchup-render-workflow
```

安装后，在新的 Codex 对话里可以这样触发：

```text
用 SketchUp 渲染工作流 skill 处理这个 skp
```

或者：

```text
Use $sketchup-render-workflow to export scenes and organize the rendered images.
```

## 目录结构

```text
sketchup-render-workflow/
├── SKILL.md
├── README.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── design_completion.md
│   └── iteration.md
└── scripts/
    ├── export_scenes_4k.rb
    ├── create_cinematic_scenes.rb
    ├── make_contact_sheet.py
    └── organize_render_images.py
```

## 核心流程

1. 在 SketchUp 中打开 `.skp` 项目。
2. 如果模型没有展示场景，先询问要生成几个候选镜头；默认 13 个，也可以改成 3 个、6 个或其他数量。
3. 如果已有展示场景，先询问“全部导出，还是只导出指定编号”。
4. 用 `export_scenes_4k.rb` 导出场景参考图。
5. 检查导出的 PNG 数量、尺寸和顺序。
6. 如果模型缺少园林、室内或软装，先审计缺失项，并让用户确认是保真渲染还是设计补全。
7. 基于每张参考图生成 AI 渲染提示词，重点保持设计还原。
8. 用户手动下载 AI 生成图后，用联系表检查是否混入旧图或重复图。
9. 用整理脚本统一重命名，并把重复版本移动到备份文件夹。
10. 如果遇到新问题，把经验补进 `SKILL.md`、`references/iteration.md` 或脚本里。

## 自动创建候选镜头

如果 `.skp` 只有模型、没有像 Enscape 场景那样设置好的视角，可以先在 SketchUp Ruby Console 中执行：

```ruby
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
```

默认会根据可见模型包围盒自动创建 13 个场景。如果只想生成 6 个，可以先设置 `SCENE_COUNT`：

```ruby
SCENE_COUNT = 6
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
```

推荐交互规则：

- 用户直接说“OK / 同意 / 继续”：使用默认 13 个
- 用户说“生成 6 个”：设置 `SCENE_COUNT = 6`
- 用户说“先试 3 个”：设置 `SCENE_COUNT = 3`

最多支持 13 个内置候选场景：

- 主入口 45 度
- 草坪庭院低机位
- 建筑正面展示
- 左右前侧景观
- 侧面和背侧关系
- 高位鸟瞰
- 屋顶与草坪关系
- 景观入口近景
- 材质立面近景
- 黄昏主视觉
- 作品集封面广角

这些镜头是“第一轮候选分镜”，不是最终摄影师判断。推荐先导出 1-3 张测试图，检查建筑是否完整入画、竖线是否垂直、地平线是否稳定，再批量导出和渲染。

### 自动找角度的当前策略

这次迭代把“模型只有几何体、没有保存视角”的情况作为重点：

- 优先用可见对象计算主体 bounds，避免隐藏或远处对象把相机拉偏。
- 主建筑展示镜头默认使用两点透视：相机高度和目标高度对齐，`Z_AXIS` 作为向上方向。
- 外观展示使用中长焦，减少广角畸变，尽量保留完整建筑和边界墙。
- 设置相机后不再调用 `zoom_extents`，避免 SketchUp 自动重构图。
- 先小批量导出并肉眼验图，通过后再进入 13 张或自定义数量的批量流程。

## SketchUp 场景导出

如果模型已经有保存好的场景，推荐先询问：

```text
检测到这个模型有 13 个场景。要全部导出，还是只导出指定编号？比如 1,3,5 或 2-6。
```

用户直接说“OK / 全部 / 继续”时，导出全部场景。

在 SketchUp Ruby Console 中执行：

```ruby
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

默认导出当前模型的全部场景，尺寸为 `3840x2160`，输出到模型所在目录旁边的：

```text
模型名_scene_exports_4k/
```

如果只想导出部分场景，可以复制脚本到项目目录，修改顶部常量：

```ruby
START_INDEX = 1
END_INDEX = 5
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

如果只想导出不连续的指定镜头：

```ruby
SCENE_INDICES = "1,3,5,8-10"
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

## 生成联系表

用于快速检查图片内容、顺序、重复图和混入旧图：

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/make_contact_sheet.py "/path/to/images" --sort mtime
```

重命名完成后，建议按文件名再检查一次：

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/make_contact_sheet.py "/path/to/images" --sort name
```

脚本依赖 Python 的 Pillow：

```bash
python3 -m pip install pillow
```

## 整理和重命名效果图

保留前 13 张，并统一命名：

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/organize_render_images.py "/path/to/downloaded/images" --prefix "星耀阁_AI效果图" --keep 1-13
```

如果第 12 张是重复图，保留第 14 张作为最终第 12 张，第 13 张作为最终第 13 张：

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/organize_render_images.py "/path/to/downloaded/images" --prefix "星耀阁_AI效果图" --keep 1-11,14,13 --duplicates 12
```

重复图会移动到：

```text
_重复备份/
```

## 渲染提示词原则

每张图都应强调：

- 使用 SketchUp 导出图作为严格建筑参考
- 保留相机角度、建筑比例、材质意图、物件位置和光影方向
- 只增强真实感、材质、植物、玻璃反射和电影感
- 不增加人物、车辆、新招牌、新家具或额外装饰
- 不重新设计建筑

如果植物是 SketchUp 符号化地被，可以明确要求：

```text
把一圈一圈的地被符号转成自然的低矮灌木、蕨类、草本、苔藓、碎石和覆土，保留原有种植区域，不改变设计布局。
```

## 设计补全模式

当模型没有完整园林、室内设计或软装时，使用 `references/design_completion.md`。

这个模式的原则是：**不假装知道缺失设计，而是先保留现有建筑，再提出可确认的设计假设。**

需要用户确认的节点：

- 是否只渲染已有设计，还是补全缺失的园林、室内或软装。
- 如果缺失设计会明显影响风格，先给 2-3 个方向让用户选择。
- 用户直接说“OK / 继续”时，默认选最克制、最贴合建筑和已有材质的方向。
- 先跑 1-3 张代表性测试图，通过后再批量生成。

室内取景会沿用外立面阶段学到的经验：

- 优先两点透视，保持墙体、门窗、柜体竖线稳定。
- 视高通常控制在 1.45-1.65m。
- 避免过广角导致房间变形；每张图只表达一个明确空间目的。
- 空房间要先判断或确认房间功能，再做软装和灯光补全。
- 如果测试图漂亮但改变了结构、门窗、楼梯或空间比例，立即停止并收紧提示词。

## 可迭代方式

这个 skill 的目标是边用边进化：

- 重复遇到的 SketchUp 导出问题，补到 `SKILL.md`
- 常见提示词修正，补到“渲染提示词原则”
- 重复写过的整理逻辑，做成 `scripts/` 里的参数
- 项目复盘经验，补到 `references/iteration.md`
- 缺失设计补全、室内取景和用户确认节点，补到 `references/design_completion.md`

保持原则：项目经验可以沉淀，但不要把某一个项目的专有路径、文件名或偏好写死到通用脚本里。

## 当前状态

第一版已经在真实项目中跑通过：

- SketchUp 2024 打开 `.skp`
- 13 个场景导出为 4K PNG
- 分批生成 AI 效果图
- 人工下载后检查联系表
- 发现重复图并备份
- 最终统一命名为 13 张效果图

2026-06-23 更新：第二轮在“只有模型、缺少展示场景”的莱茵堡项目上验证了自动找角度模块。两点透视规则能输出建筑完整、横平竖直、可继续渲染的候选图；已用两个后侧角度完成“SketchUp 候选角度 -> AI 真实化渲染”的链路测试。

2026-06-27 更新：新增“设计补全模式”。当模型缺少园林、室内或软装时，先做缺失项审计和用户确认，再补全设计方向；室内取景明确继承外立面阶段的两点透视、视高、焦距和小批量验图经验，减少后续反复调构图的成本。

## License

暂未指定开源许可证。发布到 GitHub 前，如果希望别人可以自由复用、修改和传播，建议后续补充 MIT、Apache-2.0 或其他合适的许可证。

---

# English Guide

Shared and developed by **Bang's Image**.

This is an iterative Codex skill for architectural visualization workflows with SketchUp. It helps Codex export `.skp` scenes, create faithful AI rendering prompts from the exported references, inspect generated images, remove duplicates safely, and organize the final render set with clean numbered filenames.

## What It Is For

- Open or continue from an active SketchUp model
- Export SketchUp scenes as high-resolution 4K PNG references
- Create AI image prompts that preserve the original architectural design
- Audit missing landscape, interior, or soft-furnishing design and propose confirmable completion directions
- Check whether downloaded AI renders include old images, duplicates, or ordering mistakes
- Rename final render images as `Project_AI_Render_01.png`, `Project_AI_Render_02.png`, etc.
- Move duplicate versions into `_重复备份` without deleting source files

## Installation

Clone this repository into your Codex skills directory:

```bash
mkdir -p ~/.codex/skills
git clone <this-repo-url> ~/.codex/skills/sketchup-render-workflow
```

Then invoke it in a new Codex conversation:

```text
Use $sketchup-render-workflow to export SketchUp scenes and organize the rendered images.
```

## Folder Structure

```text
sketchup-render-workflow/
├── SKILL.md
├── README.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── design_completion.md
│   └── iteration.md
└── scripts/
    ├── export_scenes_4k.rb
    ├── create_cinematic_scenes.rb
    ├── make_contact_sheet.py
    └── organize_render_images.py
```

## Main Workflow

1. Open the `.skp` project in SketchUp.
2. If the model has no presentation scenes, ask how many candidate scenes to create. Use 13 by default, but allow 3, 6, or another requested count.
3. If saved presentation scenes already exist, ask whether to export all scenes or selected scene numbers.
4. Export scenes with `export_scenes_4k.rb`.
5. Verify the exported PNG count, dimensions, and scene order.
6. If landscape, interior, or styling design is missing, audit the missing areas and ask whether to preserve only existing design or complete the missing parts.
7. Generate AI render prompts from each reference image while preserving design fidelity.
8. After manually downloading generated images, create a contact sheet to detect old files, duplicates, and ordering mistakes.
9. Rename the final set and move duplicate versions into a backup folder.
10. When a new issue appears, improve `SKILL.md`, `references/iteration.md`, or the scripts so the workflow gets better over time.

## Creating Candidate Camera Scenes

If a `.skp` file only contains geometry and has no Enscape-style presentation scenes, run this in SketchUp Ruby Console:

```ruby
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
```

By default, the script creates 13 scenes from visible model bounds. To create a smaller first batch, set `SCENE_COUNT` before loading the script:

```ruby
SCENE_COUNT = 6
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
```

Recommended interaction rule:

- If the user says "OK", "yes", or "continue" without a number, use the default 13 scenes.
- If the user asks for 6 scenes, set `SCENE_COUNT = 6`.
- If the user wants a quick 3-scene test, set `SCENE_COUNT = 3`.

The script estimates the active model's bounding box and can create up to 13 built-in scene candidates:

- Main entrance 45-degree view
- Low lawn/courtyard view
- Front elevation presentation
- Left and right landscape perspectives
- Side and rear relationship views
- High bird's-eye overview
- Roof and lawn relationship
- Landscape entrance close-up
- Material facade close-up
- Dusk hero view
- Wide portfolio cover shot

These are first-pass candidate shots, not final art direction. Export one to three test views first, check complete building framing, vertical walls, and a stable horizon, then continue to batch export and rendering.

### Current Auto-Camera Strategy

This iteration focuses on geometry-only `.skp` models without saved presentation scenes:

- Estimate the subject from visible objects, so hidden or far-away entities do not distort the camera.
- Use two-point architectural perspective for primary exterior views: the eye height and target height are aligned, with `Z_AXIS` as the up vector.
- Use moderate telephoto focal lengths for exterior presentation shots to reduce wide-angle distortion and keep the full villa and boundary walls in frame.
- Avoid `zoom_extents` after setting the camera because it can override the intended composition.
- Validate a small test batch visually before scaling to 13 or another requested scene count.

## Exporting SketchUp Scenes

If the model already has saved scenes, ask first:

```text
This model has 13 saved scenes. Export all scenes, or only specific numbers such as 1,3,5 or 2-6?
```

If the user says "OK", "all", or "continue", export all scenes.

Run this in SketchUp Ruby Console:

```ruby
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

By default, it exports every scene from the active model at `3840x2160` into:

```text
ModelName_scene_exports_4k/
```

To export a subset, copy the Ruby script into a project folder and adjust the constants near the top:

```ruby
START_INDEX = 1
END_INDEX = 5
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

To export non-contiguous selected scenes:

```ruby
SCENE_INDICES = "1,3,5,8-10"
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

## Creating a Contact Sheet

Use a contact sheet to quickly review image content, order, duplicates, and accidental old downloads:

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/make_contact_sheet.py "/path/to/images" --sort mtime
```

After renaming, verify the final order by filename:

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/make_contact_sheet.py "/path/to/images" --sort name
```

The script requires Pillow:

```bash
python3 -m pip install pillow
```

## Organizing Render Images

Keep the first 13 images and rename them:

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/organize_render_images.py "/path/to/downloaded/images" --prefix "Project_AI_Render" --keep 1-13
```

If image 12 is a duplicate, keep image 14 as final render 12 and image 13 as final render 13:

```bash
python3 ~/.codex/skills/sketchup-render-workflow/scripts/organize_render_images.py "/path/to/downloaded/images" --prefix "Project_AI_Render" --keep 1-11,14,13 --duplicates 12
```

Duplicates are moved to:

```text
_重复备份/
```

## AI Rendering Prompt Principles

Each prompt should emphasize:

- Use the SketchUp export as a strict architectural reference
- Preserve camera angle, architectural proportions, material intent, object placement, and lighting direction
- Improve only realism, materials, vegetation, reflections, shadows, and cinematic atmosphere
- Do not add people, cars, new signage, new furniture, or extra decoration
- Do not redesign the architecture

If SketchUp groundcover appears as symbolic rings or contour-like patches, add:

```text
Replace circular/ring-like groundcover symbols with natural low shrubs, ferns, grasses, moss, gravel, and soil mulch. Preserve the original planting areas and design layout.
```

## Design Completion Mode

When a model lacks landscape, interior design, styling, or soft furnishings, use `references/design_completion.md`.

The principle is: **do not pretend missing design is known; preserve the existing architecture first, then propose explicit design assumptions for user confirmation.**

User confirmation gates:

- Ask whether to render only existing design or complete missing landscape, interior, or soft furnishing design.
- If the missing design materially changes style, present 2-3 concise directions and ask the user to choose.
- If the user says "OK" or "continue" without choosing, use the most restrained direction that matches the architecture and existing materials.
- Render 1-3 representative tests first, then continue to a batch only after acceptance.

Interior camera rules inherit the exterior lessons:

- Prefer two-point perspective so walls, doors, windows, and cabinetry stay upright.
- Use normal eye height around 1.45-1.65 m.
- Avoid excessive wide-angle distortion; give each frame one clear spatial purpose.
- For empty rooms, infer or confirm room function before adding furniture and lighting.
- If a test image looks attractive but changes structure, openings, stairs, or room proportions, stop and tighten the prompt before continuing.

## Iteration Model

This skill is meant to improve through real use:

- Add repeated SketchUp export issues to `SKILL.md`
- Add useful prompt corrections to the prompt principles
- Turn repeated file-management steps into script options
- Store project learnings in `references/iteration.md`
- Store missing-design completion, interior camera, and user confirmation patterns in `references/design_completion.md`

Keep the workflow reusable. Do not hard-code one project's private paths, filenames, or preferences into the generic scripts.

## Current Status

The first version has been tested on a real project:

- Opened a `.skp` project in SketchUp 2024
- Exported 13 scenes as 4K PNG references
- Generated AI renders in batches
- Checked manually downloaded images with a contact sheet
- Detected and backed up a duplicate
- Renamed the final set into 13 clean render images

2026-06-23 update: the second iteration was validated on a geometry-only Laiyinbao villa model. The two-point camera rules produced complete, upright candidate architectural views, and two rear-side candidates successfully passed the path from SketchUp camera export to photorealistic AI rendering.

2026-06-27 update: added Design Completion Mode. When a model lacks landscape, interior, or soft furnishing design, the workflow now audits missing areas, asks for user confirmation, and carries the exterior two-point camera lessons into interior views to reduce repeated composition work.

## License

No open-source license has been selected yet. Before publishing widely, consider adding MIT, Apache-2.0, or another license that matches the intended sharing model.
