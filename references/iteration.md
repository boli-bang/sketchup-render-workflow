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
- For model-only villas, raw model bounds may include hidden or irrelevant geometry; derive candidate cameras from visible entity bounds first.
- For primary exterior views, two-point perspective is the default quality gate: align eye height and target height, keep `Z_AXIS` up, and verify vertical walls before rendering.
- Avoid `view.zoom_extents` after setting a composed SketchUp camera because it can undo carefully tuned framing.
- Validate one to three candidate views visually before scaling to a full scene set; AI rendering should not be used to rescue bad camera composition.

## 2026-06-23 Laiyinbao Auto-Camera Iteration

Problem: a `.skp` project with only model geometry did not have the 13 presentation scenes that made the Xingyaoge workflow smooth. Early automatic angles missed the building or produced weak, tilted compositions.

Implementation update:

- Updated `scripts/create_cinematic_scenes.rb` to compute bounds from visible top-level entities before falling back to raw model bounds.
- Tuned camera radius and focal lengths toward complete-building architectural views.
- Removed `zoom_extents` from the camera-setting path.
- Made primary exterior scenes two-point by aligning camera eye height and target height.

Validation result:

- Test exports kept the full villa in frame with stable verticals.
- Two rear-side candidate angles were rendered into photorealistic previews without redesigning the building massing.
- Remaining limitation: candidate scenes are still first-pass art direction and must be contact-sheet reviewed before a full production render batch.

## 2026-06-27 Design Completion Iteration

Goal: extend the workflow beyond faithful exterior rendering so it can handle models that lack landscape, interior design, or soft furnishings, while avoiding random AI redesign.

Implementation update:

- Added `references/design_completion.md` for missing-design audits, design direction confirmation, landscape completion, interior completion, and efficient interior camera rules.
- Updated `SKILL.md` so missing landscape/interior/soft furnishing design triggers the design-completion audit before AI rendering.
- Updated README and skill metadata so the GitHub documentation and Codex skill UI describe the new capability.

Process lesson:

- The exterior workflow spent significant time correcting camera composition. Interior design completion should front-load camera QA: level camera, two-point perspective, normal eye height, moderate focal length, one room purpose per frame, and 1-3 test renders before batching.
- Missing design should be treated as a user-confirmed assumption. If the user has not confirmed whether to complete missing parts, do not batch render.

## 2026-06-27 Laiyinbao Interior Camera Test

Problem: direct interior point sampling produced exports, but the results lacked spatial logic. Early candidates were too close to walls, misread terraces as interiors, or had no room purpose.

Observed results:

- Explicit eye height improved the camera compared with raw bounds-based height.
- Ray-clearance scoring helped avoid some near-wall views, but it still could not classify interior vs exterior/terrace reliably.
- The useful candidates were the ones that accidentally aligned with visible glazing, circulation, or room-shell relationships.

Process correction:

- Interior design must start from top-down floor/level interpretation, not random camera placement.
- First understand first-floor and second-floor structure, identify public/private/circulation/terrace zones, and confirm the design direction with the user.
- Only then create room-specific cameras named by purpose, such as living-to-courtyard, stair-void, bedroom-to-terrace, or material detail.
- Add cleanup of temporary AI scene pages before and after tests; too many scene tabs slow SketchUp and make iteration noisy.
