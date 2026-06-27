# Design Completion Mode

Use this reference when a SketchUp architectural model lacks interior design, landscape design, styling, or soft furnishings and the user asks to make the project feel complete.

## Core Principle

Do not pretend missing design information is already known. Preserve the existing architecture exactly, then create explicit, reviewable design assumptions for the missing parts.

Use three modes:

- **Fidelity render mode**: the model already contains the relevant design; only improve realism, materials, light, plants, and atmosphere.
- **Design completion mode**: the model has architectural intent but lacks interior, landscape, or soft furnishing detail; infer a coherent direction and ask the user to confirm before batch rendering.
- **Concept exploration mode**: the user explicitly wants alternatives; create multiple options and label them as alternatives, not as the original design.

## Missing-Design Audit

Before prompting AI renders, classify the model and references:

- Architecture: massing, facade, roof, wall openings, railings, gates, stairs, boundary walls.
- Materials: concrete, stone, wood, metal, glass, paving, water, planting materials.
- Landscape: lawn, groundcover, shrubs, trees, paving, garden edges, outdoor lighting, water features, furniture.
- Interior: room use, ceiling, floor, wall finishes, fixed cabinetry, lighting, furniture, curtains, art.
- Styling: loose furniture, cushions, tabletop items, plants, accessories, bedding, rugs.
- Camera readiness: saved scenes, candidate scenes, interior views, exterior views, detail views.

Report missing areas plainly. Example:

```text
I can preserve the architecture and facade. The model does not define detailed landscape planting or interior soft furnishings, so those must be treated as design-completion assumptions.
```

## User Confirmation Gates

Ask the user at these points when information is missing or choices affect the design direction:

1. **Scope gate**: "Should I only render what exists, or complete missing landscape/interior/soft furnishing design?"
2. **Direction gate**: present 2-3 concise design directions and ask the user to choose one before rendering many images.
3. **Batch gate**: render 1-3 representative images first; continue only after the user accepts the direction.
4. **Correction gate**: if a generated image changes architecture or over-designs missing parts, stop and tighten the prompt before continuing.

If the user says "OK", "continue", or gives no preference at the direction gate, choose the most conservative option that best matches the architecture and existing materials.

## Design Direction Heuristics

Infer from architecture, not from arbitrary taste:

- **Modern minimalist villa**: restrained planting, linear paving, low shrubs, warm indirect lighting, stone/concrete/wood/glass continuity, quiet furniture.
- **Modern luxury villa**: richer stone texture, precise garden lighting, sculptural planting, refined outdoor seating, warm interior accents, but no excessive decoration.
- **New Chinese / contemporary oriental**: layered courtyards, stone, bamboo or pine-like vertical planting, moss/grass groundcover, calm water or gravel only when site logic supports it.
- **Natural resort villa**: softer grasses, organic planting edges, relaxed outdoor seating, warm dusk lighting, natural wood and woven textures.
- **Urban townhouse / compact courtyard**: clean boundary walls, controlled planting beds, functional terrace furniture, privacy screens, efficient lighting.

When uncertain, default to a restrained, high-end natural-modern direction because it is less likely to fight the architecture.

## Landscape Completion Rules

Preserve:

- Building footprint, boundary walls, gates, steps, terraces, existing paths, and planting zones.
- Camera angle, sun direction, visible material intent, and site circulation.

Complete only where missing:

- Replace symbolic or ring-like groundcover with natural low shrubs, grasses, ferns, moss, gravel, soil mulch, and organic edges.
- Add planting density gradually; do not hide facade, windows, gates, or key massing.
- Add garden lighting only when it supports the existing paths, walls, steps, or planting beds.
- Keep species language coherent; do not mix tropical, Japanese, English garden, and desert planting in one default scheme.

Avoid:

- Large trees blocking the architecture unless the model already implies them.
- New water features, sculptures, pergolas, people, cars, signage, or furniture unless requested.
- Redesigning hardscape geometry or moving circulation.

## Interior Completion Rules

Interior work must be more careful than exterior work because missing information is larger.

Preserve:

- Architectural shell, openings, ceiling heights, structural walls, stairs, window locations, and view direction.
- Any visible fixed elements such as built-in cabinets, fireplaces, railings, kitchen islands, or bathroom fixtures.

Complete only after choosing a direction:

- Define room function first: living, dining, bedroom, study, tea room, hallway, bathroom, or lobby.
- Use the architecture's exterior material language as the base palette.
- Add furniture at believable scale and keep circulation clear.
- Use lighting as a design structure: daylight from real openings, warm interior practical lights, concealed linear light only where it fits the style.
- Use soft furnishing to support the chosen style: rugs, curtains, cushions, bedding, side tables, art, plants.

Avoid:

- Changing windows, door positions, stairs, room proportions, or structural geometry.
- Filling every empty area; high-end interiors need negative space.
- Overwriting a minimalist architectural shell with a generic showroom look.
- Adding brand logos, text, people, or implausible luxury props.

## Efficient Interior Camera Rules

Carry over the exterior camera lessons before spending time rendering:

- Use eye height around 1.45-1.65 m for normal room views.
- Keep the camera level for most interior shots; use two-point perspective so verticals remain straight.
- Place the camera near a room corner or doorway only when it does not exaggerate distortion.
- Use moderate focal lengths for interiors; avoid very wide views unless the room is tiny and the user accepts distortion.
- Show one clear room purpose per frame. Do not try to show every wall at once.
- Keep windows, doors, ceiling lines, and cabinetry edges straight; reject references with tilted verticals before rendering.
- Export one test image per interior scene type first: wide room, material detail, view toward window, and circulation/threshold.
- If the room is empty, first ask or infer the room function. Do not furnish an undefined space blindly.

Suggested first-pass interior scene set:

1. Main living room wide view.
2. Living/dining relationship.
3. Kitchen or dining detail if visible.
4. Bedroom atmosphere if private rooms exist.
5. Stair/hallway circulation.
6. Window/view relationship.
7. Material and soft furnishing detail.

## Prompt Pattern

Use this structure for design completion prompts:

```text
Use the SketchUp export as a strict architectural reference.
Preserve the existing architecture, camera angle, proportions, openings, walls, ceiling, floor, structural elements, visible materials, and lighting direction.

Mode: design completion, not redesign.
Missing design to complete: <landscape / interior / soft furnishing>.
Chosen direction: <confirmed direction>.
Complete only the missing elements in a way that fits the existing architecture.

Required additions: <concise list>.
Hard constraints: no architectural redesign, no moved windows/doors/walls/stairs, no changed massing, no people, no cars, no logos, no text, no excessive decoration.
Quality target: photorealistic high-end architectural visualization with natural materials, believable scale, and cinematic but controlled light.
```

## Stop Conditions

Stop and ask the user instead of continuing when:

- The model does not reveal enough to infer room function.
- The user has not confirmed whether missing parts should be completed or left empty.
- A generated image changes architecture, openings, or hardscape geometry.
- The first test image is visually impressive but violates the design intent.
- Multiple plausible design styles fit equally well and the choice would strongly change the result.
