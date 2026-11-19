---
title: "টার্নাক্স v3 component architecture"
description: "টার্নাক্স v3 component-এর দায়িত্ব, dependency, interface ও ownership boundary।"
lang: "bn"
alt_url: "/docs/v3/COMPONENT-ARCHITECTURE.html"
---

## Component architecture

**অবস্থা: নকশা সম্পন্ন।** Component-গুলো versioned local interface দিয়ে যোগাযোগ করে। একটি component না থাকলেও সম্পর্কহীন product area কাজ চালিয়ে যেতে পারবে।

| Component | কোথায় চলে | যার মালিক | নির্ভরতা | যার মালিক হবে না |
|---|---|---|---|---|
| `tx` CLI | Termux host | command parsing, স্থির UX ও exit status | Manager core | guest-নির্দিষ্ট business logic |
| Manager core | Termux host | guest registry, state transition ও policy | Termux APIs, PRoot-Distro | GUI rendering বা model internals |
| Control Center | Termux host | dashboard, action form ও event display | Local Manager API | সরাসরি rootfs লেখা বা Android permission bypass |
| Guest supervisor | Termux host | একটি guest-এর process/display lifecycle | PRoot-Distro, Termux:X11 | অন্য guest-এর process tree |
| Workspace adapter | host ও guest | guest profile, shell, desktop ও scoped mount | distro package manager | host CLI installation |
| Compute service | host metadata ও guest runtime | capability ও backend নির্বাচন | Mesa/Turnip/runtime pack | device-name heuristic-ভিত্তিক দাবি |
| Workload manager | Termux host | pack manifest, download, verify, install ও remove | Artifact store, compute service | ব্যবহারকারীর model store, যদি না নির্বাচিত হয় |
| AI workload runtime | Termux host ও নির্বাচিত guest/runtime | Ternux workload, model metadata ও job lifecycle | Ternux manifest ও যাচাইকৃত artifact | অন্য product API, private store বা service |
| Device Bridge | Termux host | permission-aware API call ও file transfer | Termux:API | সক্রিয় request ছাড়া persistent capture |
| Diagnostics | Termux host | structured check ও নিরাপদ repair plan | component health API | scope ছাড়া cleanup বা guest deletion |

## Dependency-এর দিক

CLI ও UI manager interface-এর উপর নির্ভর করবে। Manager presentation নয়, adapter-এর উপর নির্ভর করবে। Workspace ও workload adapter supervisor ব্যবহার করতে পারে; তারা CLI formatting import করবে না। Device Bridge ও AI adapter সীমিত interface দিয়ে manager-কে capability জানাবে। Guest package host shell file source করে manager internals ডাকতে পারবে না।

```text
CLI ───────┐
           ├── Manager API ── Guest registry ── Workspace adapter ── PRoot-Distro
Control UI ┘        ├──────── Compute service ── runtime adapters
                    ├──────── Workload manager ── verified artifacts
                    ├──────── Device Bridge ───── Termux:API
                    └──────── AI workload runtime ── verified Ternux artifacts
```

## Component contract

- ID স্থির opaque value; distro label ও display number বদলাতে পারে, primary key নয়।
- দীর্ঘ কাজ job ID, phase, progress, cancelability ও শেষের structured result দেবে। CLI ও UI একই event stream দেখাতে পারবে।
- Error-এ stable code, নিরাপদ user message, component, retry পরামর্শ ও ঐচ্ছিক log reference থাকবে। Secret/raw environment value থাকবে না।
- প্রতিটি পরিবর্তনকারী operation execution-এর আগে target, প্রত্যাশিত বর্তমান state ও rollback আচরণ জানাবে।
- ঐচ্ছিক capability explicit manifest দিয়ে খুঁজবে। অনুপস্থিত হলে কারণসহ `unavailable` দেখাবে, কৃত্রিম success নয়।

বাস্তবায়নের boundary [ADR index](ADR/README.html) ও [implementation status](../project/IMPLEMENTATION-STATUS.html)-এ নথিভুক্ত।
