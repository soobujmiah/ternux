---
title: "টার্নাক্স পরবর্তী সংস্করণ security model"
description: "Threat boundary, least privilege, artifact verification ও নিরাপদ data ownership।"
lang: "bn"
alt_url: "/docs/next/architecture/SECURITY-MODEL.html"
---

## Security model

**অবস্থা: নকশা সম্পন্ন।** Android-এর Termux app sandbox প্রধান security boundary। PRoot process identity ও filesystem view বদলায়, কিন্তু Termux UID থেকে kernel-স্তরের বিচ্ছিন্নতা দেয় না। Ternux-কে এই সীমা সঠিকভাবে বলতে হবে।

## Asset ও threat

রক্ষার asset: Termux credential/private file, guest data, model, Android media, sensor access, signing key, update artifact এবং network-facing local service। Threat-এর মধ্যে আছে malicious guest package, untrusted extension, compromised download, local web request forgery, path traversal, symlink substitution, stale process identity, অতিরিক্ত storage grant এবং ভুল cleanup।

## আবশ্যিক control

- Native service socket private directory ও restrictive mode-এ থাকবে; UI endpoint loopback-এ bind করবে এবং origin ও per-session action token validate করবে।
- Artifact manifest source, version, architecture, digest, license ও install ownership pin করবে। Signature verification অগ্রাধিকার; pinned checksum transport ও accidental substitution সামলায়, কিন্তু publisher identity-এর বিকল্প নয়।
- Installer path allowlist root-এর নিচে resolve করবে; write/cleanup-এর আগে symlink, traversal, concurrent mutation ও unsafe ownership যাচাই করবে।
- Guest/device permission সীমিত ও প্রত্যাহারযোগ্য হবে। Camera/microphone on-demand; model discovery read-only; automatic cleanup ownership boundary পার হবে না।
- Update ও removal stage, journal এবং recovery-সহ হবে। Failure-এ সর্বশেষ good executable বা user data মুছবে না।
- User স্পষ্টভাবে report export না করলে diagnostics prompt, media, access token, environment secret ও private absolute path redacted করবে।

## Extension trust

Extension versioned manifest দিয়ে permission জানাবে; install-এর আগে capability ঘোষণা করবে। প্রথম extension হবে data/command bundle, auto-executed install hook ছাড়া। ভবিষ্যতে executable hook এলে reviewed allowlist, explicit user confirmation, ঘোষিত filesystem scope ও audit করা rollback লাগবে। Extension নীরবে startup service যোগ বা guest mount বাড়াতে পারবে না।

## Uninstall ও recovery

`tx uninstall` confirmation চাওয়ার আগে Ternux-owned host path ও registered guest তালিকাভুক্ত করবে। Default-এ user model store ও সম্পর্কহীন Termux package থাকবে। Confirmation-এ category অনুযায়ী byte ও path দেখাবে। Recovery পরিচিত manager state ঠিক করবে; অচেনা file recursive delete করবে না বা explicit selection ছাড়া guest reinstall করবে না।
