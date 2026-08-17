---
title: "Documentation"
description: "Choose an installation route, operate ternux safely, inspect its architecture, and evaluate device evidence without overstating what was tested."
lang: "en"
alt_url: "/bn/docs/"
---

This documentation is organized around decisions and tasks rather than the
installer's source tree. If this is your first visit, choose a route below. If
something is already broken, go directly to [Troubleshooting](TROUBLESHOOTING.html).

## Choose your installation path

<div class="path-chooser">
  <div class="path-choice"><b>Fastest</b><strong>Quick start</strong><p>Use the hosted installer, launch the desktop, and verify the renderer.</p></div>
  <div class="path-choice"><b>Review first</b><strong>Clone and inspect</strong><p>Pin the repository, check every shell target, then run the local installer.</p></div>
  <div class="path-choice"><b>Full control</b><strong>Manual setup</strong><p>Perform the host, guest, graphics, audio, and launcher steps yourself.</p></div>
</div>

<div class="doc-grid">
  <a class="doc-card" href="QUICK-START.html"><span class="doc-card__icon">01</span><strong>Quick start</strong><span>The shortest path to a launched and verified workspace.</span></a>
  <a class="doc-card" href="INSTALLATION.html"><span class="doc-card__icon">02</span><strong>Installation</strong><span>Requirements, review-first route, phases, flags, updates, and removal.</span></a>
  <a class="doc-card" href="MANUAL.html"><span class="doc-card__icon">03</span><strong>Manual installation</strong><span>An auditable command-by-command setup with complete launcher behavior.</span></a>
  <a class="doc-card" href="FAQ.html"><span class="doc-card__icon">?</span><strong>Before you install</strong><span>Root, compatibility, storage, battery, privacy, and project limits.</span></a>
</div>

## Operate the workspace

<div class="doc-grid">
  <a class="doc-card" href="USAGE.html"><span class="doc-card__icon">$</span><strong>Daily usage</strong><span>Start and stop sessions, manage files, run workloads, and back up data.</span></a>
  <a class="doc-card" href="CONFIGURATION.html"><span class="doc-card__icon">{ }</span><strong>Configuration</strong><span>Graphics backends, launch variables, audio, locale, fonts, and file locations.</span></a>
  <a class="doc-card" href="TROUBLESHOOTING.html"><span class="doc-card__icon">!</span><strong>Troubleshooting</strong><span>Symptom-led checks, `ternux doctor`, safe repair, and clean reinstall paths.</span></a>
  <a class="doc-card" href="CLI.html"><span class="doc-card__icon">--</span><strong>CLI reference</strong><span>Every public command, option, status behavior, and documented JSON surface.</span></a>
</div>

## Understand the system

<div class="doc-grid">
  <a class="doc-card" href="ARCHITECTURE.html"><span class="doc-card__icon">→</span><strong>Architecture</strong><span>Follow display, audio, filesystem, process, Zink/Turnip, and VirGL paths.</span></a>
  <a class="doc-card" href="BENCHMARKS.html"><span class="doc-card__icon">∿</span><strong>Evidence &amp; benchmarks</strong><span>Inspect all captured scene values, caveats, boundaries, and reproduction steps.</span></a>
  <a class="doc-card" href="FAQ.html"><span class="doc-card__icon">?</span><strong>FAQ</strong><span>Direct answers about what ternux supports, protects, and deliberately does not do.</span></a>
  <a class="doc-card" href="../CONTRIBUTING.html"><span class="doc-card__icon">+</span><strong>Contributing</strong><span>Submit code, documentation, translations, issue reports, or new device evidence.</span></a>
</div>

## Read claims correctly

ternux keeps four evidence levels separate. This vocabulary applies across the
README, website, issue reports, and benchmark submissions.

<div class="evidence-key">
  <div><b>Measured</b><strong>Captured numeric output</strong><span>A preserved command, environment, score, FPS value, or other direct measurement.</span></div>
  <div><b>Observed</b><strong>Direct non-numeric behavior</strong><span>For example, an application-reported renderer or a confirmed working path.</span></div>
  <div><b>Reported build</b><strong>A successful build report</strong><span>Useful compatibility evidence, but not a runtime or performance benchmark.</span></div>
  <div><b>Untested</b><strong>No result established</strong><span>No affirmative compatibility or performance claim should be inferred.</span></div>
</div>

> **Current evidence boundary:** the published graphics snapshot is from one
> Redmi Turbo 4 Pro. The archived renderer and all 66 glmark2 scene values show
> what happened on that device, not what every Android device will produce.

## Project and support

- Read the [Changelog](../CHANGELOG.html) for published history.
- Read [Contributing](../CONTRIBUTING.html) before sending a patch or device result.
- Use the [security policy](https://github.com/soobujmiah/ternux/security/policy)
  for vulnerability reports rather than a public issue.
- Open a [GitHub issue](https://github.com/soobujmiah/ternux/issues/new/choose)
  for reproducible bugs, documentation gaps, and feature proposals.
