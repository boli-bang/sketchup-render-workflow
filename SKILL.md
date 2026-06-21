---
name: sketchup-render-workflow
description: End-to-end SketchUp rendering workflow for .skp architectural projects. Use when Codex needs to open or automate SketchUp, export named scenes/views to high-resolution PNG references, create faithful AI image-render prompts from those references, compare/check rendered outputs, remove duplicates, and organize final effect images into clean numbered folders for iterative architectural visualization work.
---

# SketchUp Render Workflow

## Overview

Use this skill to run a repeatable, iterative pipeline:
SketchUp scene export -> visual QA/contact sheets -> AI render prompting -> download/import cleanup -> final numbered folder.

Prioritize fidelity to the model. The rendered image should preserve camera, massing, material intent, object positions, and lighting direction unless the user explicitly asks to redesign.

## Workflow

1. Identify the `.skp` file, active SketchUp version, and intended output folder.
2. If SketchUp is already open, use the active model. Otherwise open the file with the installed SketchUp app.
3. If the model has no useful saved scenes, ask how many candidate cinematic scenes to create. Default to 13 when the user says OK/yes/continue or gives no number. Create candidate scenes with `scripts/create_cinematic_scenes.rb`.
4. If useful saved scenes exist, ask whether to export all scenes or only specific scene numbers. Export scene references with `scripts/export_scenes_4k.rb` through SketchUp Ruby Console or a SketchUp automation route.
5. Verify the exported PNG count, dimensions, and scene ordering.
6. Generate a contact sheet with `scripts/make_contact_sheet.py` whenever there are many reference or rendered images.
7. Prompt image generation from each reference with strict fidelity language. Do not add people, cars, logos, furniture, or new architectural elements unless requested.
8. After the user downloads rendered images, use `scripts/organize_render_images.py` to rename the final set and move duplicates to `_重复备份`.
9. Preserve intermediate references and logs. Never delete duplicates unless the user explicitly asks.

## Creating Candidate Scenes

For a model that only contains geometry and lacks presentation scenes, first ask for the scene count:

```text
This model has no presentation scenes. Create the default 13 cinematic candidate scenes, or use another number such as 3 or 6?
```

If the user agrees without giving a number, use 13.

Create the default 13 scenes:

```ruby
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
```

Create a custom number of scenes:

```ruby
SCENE_COUNT = 6
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/create_cinematic_scenes.rb"
```

The script estimates the model bounds and adds up to 13 scenes named `AI Cinematic 01...13`: entrance 45-degree views, low lawn/courtyard views, side and rear views, bird's-eye views, material close-ups, dusk hero, and a wide cover shot.

Treat these as a first pass, not final art direction. Export them, make a contact sheet, then keep, adjust, or replace weak angles. The goal is to turn a "model-only" project into a scene-based project before AI rendering.

## Exporting From SketchUp

Use `scripts/export_scenes_4k.rb` as the default Ruby exporter. It exports all scenes in the active model to a sibling folder named after the model, with numbered PNG files and a log.

Before exporting a model with saved scenes, report the scene count and ask:

```text
This model has 13 saved scenes. Export all scenes, or only specific numbers such as 1,3,5 or 2-6?
```

If the user says OK/yes/continue without selecting numbers, export all scenes.

Typical SketchUp Ruby Console command:

```ruby
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

If the user only wants a contiguous range:

```ruby
START_INDEX = 2
END_INDEX = 6
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

If the user wants non-contiguous scenes:

```ruby
SCENE_INDICES = "1,3,5,8-10"
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

Prefer 3840x2160 unless the user requests another size.

## Prompting AI Renders

For each render prompt, include:

- The scene number/name and "use the SketchUp export as strict architectural reference".
- Preserve camera angle, composition, proportions, object placement, visible architecture, material intent, signs, furniture, plants, rocks, and paving.
- Improve only realism: concrete, glass, wood, metal, shadows, reflections, vegetation, atmosphere.
- Explicit negative constraints: no redesign, no people, no cars, no extra signage/logos/decor, no moved objects.
- Project-specific correction requests, such as replacing symbolic ring-like groundcover with natural shrubs, ferns, grasses, moss, gravel, soil mulch, varied leaf density, and organic edges.

When exact fidelity matters, render in small batches and inspect results before continuing.

## Organizing Results

When the user downloads generated images manually, first make a contact sheet. Use modification-time sorting for raw downloads because browser filenames are often inconsistent:

```bash
python3 /Users/bang/.codex/skills/sketchup-render-workflow/scripts/make_contact_sheet.py "/path/to/downloaded/images" --sort mtime
```

Then organize the confirmed set:

```bash
python3 /Users/bang/.codex/skills/sketchup-render-workflow/scripts/organize_render_images.py "/path/to/downloaded/images" --prefix "项目_AI效果图" --keep 1-13
```

Use `--duplicates` for extra images that should be moved to `_重复备份`.

After renaming, verify the final folder by filename:

```bash
python3 /Users/bang/.codex/skills/sketchup-render-workflow/scripts/make_contact_sheet.py "/path/to/downloaded/images" --sort name
```

## Iteration

Read `references/iteration.md` when improving this skill after a real project. Update the smallest useful part: prompt pattern, SketchUp export note, or script behavior. Keep the workflow project-agnostic; put project-specific names only in examples or command arguments.

## Resources

- `scripts/export_scenes_4k.rb`: SketchUp Ruby exporter for active model scenes.
- `scripts/create_cinematic_scenes.rb`: Create 13 candidate cinematic camera scenes for model-only projects.
- `scripts/make_contact_sheet.py`: Create a labeled contact sheet from image files.
- `scripts/organize_render_images.py`: Rename a selected image set and move duplicates to backup.
- `references/iteration.md`: Rules for evolving the skill after repeated use.
