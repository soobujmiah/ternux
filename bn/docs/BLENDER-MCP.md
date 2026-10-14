---
title: "Blender GPU MCP"
description: "সংযুক্ত coding-agent client থেকে Ternux-এর local Blender GPU MCP ব্যবহার করুন।"
lang: "bn"
alt_url: "/docs/BLENDER-MCP.html"
---

Ternux-এ standard-library-only একটি local MCP server আছে। সংযুক্ত agent-কে
প্রতিষ্ঠিত headless Blender GPU route চালানোর জন্য এটি তিনটি tool দেয়। এটি
মাপা EEVEE workflow-এর একই
`DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup` path ব্যবহার করে;
Blender-এর ভেতরে plugin যোগ করে না, render baseline-ও বদলায় না।

## Agent-এর কাছে tool দেখা যাচ্ছে কি না দেখুন

MCP access নির্দিষ্ট client session-এর জন্য। নিচের command বর্তমান user-এর
**Claude Code**-এ server register করে:

```bash
claude mcp add --scope user blender-gpu -- python3 ~/ternux/tools/blender-gpu-mcp/server.py
```

যে environment-এ Claude Code এবং Ternux checkout আছে, সেখানে command-টি একবার
চালান। তারপর Claude Code session-এ `/mcp` লিখুন বা নতুন session শুরু করুন;
`blender-gpu`-তে `gpu_check`, `render_script` এবং `render_blend`—তিনটি tool
দেখাচ্ছে কি না নিশ্চিত করুন।

অন্য coding-agent client-কে এই local stdio server-এর সঙ্গে আলাদাভাবে MCP
connect করতে হবে। Claude Code-এ register করলেই সব agent tool-গুলো পায় না।
Render বলতে বলার আগে বর্তমান session-এ tool-নামগুলো আছে কি না agent যাচাই করবে।
না থাকলে আগে MCP client connect/configure করতে হবে; tool call না করে call করেছে
বলে agent দাবি করবে না।

## কোন tool কখন ব্যবহার করবেন

| Tool | কাজ | মূল input |
|---|---|---|
| `gpu_check` | Display ও Zink/Turnip renderer প্রস্তুত কি না দেখে। Zero-frame render হলে আগে এটি চালান। | ঐচ্ছিক display; default `:9`। |
| `render_script` | Blender Python script চালায়; চাইলে আগে `.blend` খোলে। | Absolute script path; ঐচ্ছিক absolute `.blend`, script argument, display ও timeout। |
| `render_blend` | `.blend` থেকে একটি frame, frame range বা পুরো scene render করে। | Absolute `.blend` path ও absolute output prefix; ঐচ্ছিক frame সীমা, display ও timeout। |

সংযুক্ত agent-কে সাধারণ ভাষায় বলতে পারেন:

- “Render-এর আগে Blender GPU route check করো।” → `gpu_check`
- “`/absolute/project/render.py`-কে
  `/absolute/project/test.png`-এ render করো।” → `render_script`; output path-টি
  script argument হিসেবে `--`-এর পরে দিন।
- “`/absolute/project/scene.blend` থেকে frame 1–120
  `/absolute/project/frames/frame_`-এ render করো।” → `frame_start: 1` ও
  `frame_end: 120` দিয়ে `render_blend`।

সাথে থাকা smoke scene-টি `render_script` দিয়ে চালাতে absolute path দিন:

```text
script:      /absolute/path/ternux/tools/blender-gpu-mcp/examples/smoke_render.py
script_args: ["/absolute/path/to/output/frame.png"]
```

একই render-এর সরাসরি terminal command:

```bash
DISPLAY=:9 GALLIUM_DRIVER=zink blender -b --factory-startup \
  --python /absolute/path/ternux/tools/blender-gpu-mcp/examples/smoke_render.py \
  -- /absolute/path/to/output/frame.png
```

`:9` display আগে থেকে চালু না থাকলে server নিজে Xvfb চালায়। Absolute path
লাগে; directory ঘেঁটে file খোঁজে না, কিছু delete-ও করে না। Tool response-এ
লেখা frame, render time, output path ও failure diagnosis থাকে।

## Zero-frame ফলাফল বুঝুন

আগে `gpu_check` চালিয়ে তার diagnosis দেখুন:

- **`EGL_BAD_MATCH`**: Blender ব্যবহারযোগ্য X display/GL context পায়নি।
  Headless route-এ `:9`-এ Xvfb দরকার।
- **`llvmpipe` সহ `Illegal instruction` / `SIGILL`**: Mesa software renderer
  বেছে নিয়েছে। সঠিক Adreno run-এ Zink-এর ওপর Turnip দেখা উচিত; retry করার
  আগে `gpu_check`-এর renderer দেখুন।

এগুলো display/renderer setup-এর সমস্যা নির্দেশ করে; scene-এ ত্রুটি আছে তা
প্রমাণ করে না। প্রতিষ্ঠিত Redmi workstation-এ Cycles বা software rendering-এ
পাল্টাবেন না।

## Evidence

2026-10-14-এ প্রতিষ্ঠিত Redmi Turbo 4 Pro setup Zink over Adreno 825 / Mesa
Turnip দেখিয়েছে। 320×180 EEVEE Next smoke frame Blender-এর হিসাবে 2.49 সেকেন্ড
এবং process start ও shader compile-সহ মোট wall time 6.92 সেকেন্ড নিয়েছে। এটি
ঐ তারিখের মাপা ফলের pointer—নতুন benchmark নয়, অন্য device-এর নিশ্চয়তাও নয়।
[MCP implementation ও verification](https://github.com/soobujmiah/ternux/blob/main/tools/blender-gpu-mcp/README.md)
এবং [render workflow](https://github.com/soobujmiah/ternux/blob/main/experiments/cartoon-pipeline/README.md)
দেখুন।
