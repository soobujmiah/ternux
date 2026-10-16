import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const dist = path.join(root, "dist");
const copy = (from, to) =>
  fs.cpSync(path.join(root, from), path.join(dist, to), {
    recursive: true,
    force: true,
  });
copy("assets/fonts", "assets/fonts");
copy("assets/img", "assets/img");
for (const file of [
  "LICENSE",
  "LICENSE-APACHE-2.0",
  "LICENSE-COMMERCIAL-ADDENDUM.md",
  "LICENSE-SCOPE.md",
  "NOTICE",
  "THIRD_PARTY_NOTICES.md",
]) {
  fs.copyFileSync(path.join(root, file), path.join(dist, file));
}
// Preserve the established directory URLs for the two documentation indexes.
for (const [from, to] of [
  ["docs.html", "docs/index.html"],
  ["bn/docs.html", "bn/docs/index.html"],
  ["bn.html", "bn/index.html"],
]) {
  const source = path.join(dist, from);
  const target = path.join(dist, to);
  if (fs.existsSync(source)) {
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.copyFileSync(source, target);
  }
  if (fs.existsSync(source)) fs.rmSync(source);
}
const publicRoutes = [];
function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(file);
    else if (entry.name.endsWith(".html")) {
      const rel = path.relative(dist, file).split(path.sep).join("/");
      if (
        rel.includes("/SEO.") ||
        rel.includes("/ACCELERATOR-RELEASE-PLAN.") ||
        ["docs.html", "bn.html", "bn/docs.html"].includes(rel)
      )
        continue;
      publicRoutes.push(rel === "index.html" ? "/" : `/${rel}`);
    }
  }
}
walk(dist);
const date = new Date().toISOString().slice(0, 10);
const normalize = (route) =>
  route === "/index.html"
    ? "/"
    : route.endsWith("/index.html")
      ? route.slice(0, -10)
      : route;
const routes = [...new Set(publicRoutes.map(normalize))].sort();
const alternate = (route) =>
  route === "/"
    ? "/bn/"
    : route === "/bn/"
      ? "/"
      : route.startsWith("/bn/")
        ? route.slice(3)
        : `/bn${route}`;
const urls = routes
  .map((route) => {
    const other = alternate(route);
    const links = routes.includes(other)
      ? `\n    <xhtml:link rel="alternate" hreflang="${route.startsWith("/bn") ? "bn" : "en"}" href="https://soobujmiah.github.io/ternux${route}" />\n    <xhtml:link rel="alternate" hreflang="${route.startsWith("/bn") ? "en" : "bn"}" href="https://soobujmiah.github.io/ternux${other}" />\n    <xhtml:link rel="alternate" hreflang="x-default" href="https://soobujmiah.github.io/ternux${route.startsWith("/bn") ? other : route}" />`
      : "";
    return `  <url><loc>https://soobujmiah.github.io/ternux${route}</loc><lastmod>${date}</lastmod>${links}\n  </url>`;
  })
  .join("\n");
fs.writeFileSync(
  path.join(dist, "sitemap.xml"),
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${urls}\n</urlset>\n`,
);
console.log(`Finalized ${publicRoutes.length} HTML routes and sitemap.xml`);
