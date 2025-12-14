```markdown
---
title: Image generation prompts — obs
created: 2025-12-14
tags: [assets,images,prompts]
---

Below are ready-to-use prompts and variations for generating images for the `obs` project. Replace `<repo-url>` or any placeholder text as needed. For logos prefer a vector/SVG output.

1) Logo — minimalist vector (SVG)

Prompt (for vector-capable generator / SVG export):

"Minimalist vector monogram logo for a CLI tool named 'obs', lowercase letters, geometric and modern sans-serif, badge-style: rounded square background with subtle gradient (deep teal #0b5f7f to bright cyan #2bb3d9), white lowercase 'obs' centered, bold weight, high contrast, optimized for small sizes and favours simple shapes, transparent padding, no photoreal textures, deliver as SVG or clean PNG with transparent background. --v 5 --svg"

Variations:
- White wordmark on dark rounded-square badge.
- Dark wordmark on light badge.
- Circle badge variant (for avatar/OG fallback).

2) OG / Social preview (1200×630)

Prompt (illustration / graphic):

"1200x630 clean hero image for blog post 'Building obs — CLI Obsidian Companion'. Modern flat style, subtle code/terminal motifs, top-left: small obs monogram badge, center: title text area 'Building obs — CLI Obsidian Companion' (leave space for text overlay), background: diagonal teal-to-cyan gradient with soft circuit/terminal grid pattern, accent icons: small terminal window, markdown file, arrow showing workflow, overall minimal, high readability, deliver as PNG 1200x630, no heavy photographic elements." 

Midjourney-style short prompt:
"hero graphic, teal gradient background, terminal + markdown icons, modern flat, high contrast, minimal, 1200x630"

3) Workflow diagram (vector)

Prompt (diagram-style SVG):
"Simple vector workflow diagram showing: Installer -> scripts -> Vault -> Editor. Use clean line icons, arrows, and short labels, monocolor strokes (dark teal #0b5f7f), rounded corners, export as SVG for embedding in docs." 

4) Photoreal / Illustration variants (if desired)

Prompt (photoreal prompt example):
"Close-up photo-style scene of a laptop terminal showing markdown files and a small 'obs' logo sticker on the laptop — warm ambient lighting, shallow depth of field, editorial tech vibe, 3:2 crop, high detail." 

5) Generation / usage notes

- For logos and diagrams ask your image tool to export SVG or vector-native output when possible.
- For Midjourney: keep prompts short and iterate; use `--ar 1200:630` or `--ar 16:9` for landscape hero crops.
- For Stable Diffusion: use img2img or an SVG-aware front-end if you need crisp vector-like lines; outline 'SVG-friendly' in the prompt.

Replace color hexes or text with your brand choices. When posting, replace `<repo-url>` with the repository URL.

```
