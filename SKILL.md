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
3. Export scene references with `scripts/export_scenes_4k.rb` through SketchUp Ruby Console or a SketchUp automation route.
4. Verify the exported PNG count, dimensions, and scene ordering.
5. Generate a contact sheet with `scripts/make_contact_sheet.py` whenever there are many reference or rendered images.
6. Prompt image generation from each reference with strict fidelity language. Do not add people, cars, logos, furniture, or new architectural elements unless requested.
7. After the user downloads rendered images, use `scripts/organize_render_images.py` to rename the final set and move duplicates to `_重复备份`.
8. Preserve intermediate references and logs. Never delete duplicates unless the user explicitly asks.

## Exporting From SketchUp

Use `scripts/export_scenes_4k.rb` as the default Ruby exporter. It exports all scenes in the active model to a sibling folder named after the model, with numbered PNG files and a log.

Typical SketchUp Ruby Console command:

```ruby
load "/Users/bang/.codex/skills/sketchup-render-workflow/scripts/export_scenes_4k.rb"
```

If the user only wants a subset, edit the constants at the top of the copied script or create a project-local copy before loading it. Prefer 3840x2160 unless the user requests another size.

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
- `scripts/make_contact_sheet.py`: Create a labeled contact sheet from image files.
- `scripts/organize_render_images.py`: Rename a selected image set and move duplicates to backup.
- `references/iteration.md`: Rules for evolving the skill after repeated use.
