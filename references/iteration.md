# Iteration Notes

Use this reference when updating the skill after a real SketchUp rendering project.

## What to Preserve

- Keep camera and composition fidelity as the highest priority.
- Keep scene export and render organization deterministic.
- Keep scripts generic: accept paths, prefixes, ranges, and output folders as arguments.
- Keep project-specific facts out of `SKILL.md` unless they are examples.

## What to Add After New Failures

- Add a prompt clause when image generation repeatedly changes a design element.
- Add a script option when file organization required repeated manual shell logic.
- Add a SketchUp exporter note when a Ruby API issue or macOS permission issue repeats.
- Add a visual QA rule when a mismatch would be easy to catch from a contact sheet.

## Current Learned Patterns

- SketchUp AI-render references should be exported as native PNGs, not screenshots, whenever possible.
- Contact sheets prevent mixing old downloads with current project images.
- User-downloaded image folders may contain one extra duplicate; move duplicates to `_重复备份` instead of deleting.
- Generated-image tools may display results inline without exposing a file path; ask the user to download images before final organization.
- For landscape visualizations, explicitly replace symbolic ring-like groundcover with organic planting while preserving planting locations.
