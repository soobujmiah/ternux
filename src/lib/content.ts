import fs from "node:fs";
import path from "node:path";
import { marked } from "marked";
import { gfmHeadingId } from "marked-gfm-heading-id";

marked.use(gfmHeadingId());
const root = process.cwd();
const base = "/ternux";

function rewriteHtml(html: string, route: string) {
  const sourceDir = path.dirname(path.join(root, route));
  return html
    .replace(
      /\b(href|src)=(['"])(\/[^#][^'"]*)\2/g,
      (_m, attr, quote, value) => ` ${attr}=${quote}${base}${value}${quote}`,
    )
    .replace(
      /href=(['"])([^:'"#][^'"]*?)\.md(#[^'"]*)?\1/g,
      (_m, q, value, hash = "") => {
        const target = path.resolve(sourceDir, `${value}.md`);
        const relative = path.relative(root, target).split(path.sep).join("/");
        const publicDoc =
          /^(docs|bn\/docs)\/(?!README|SEO\.md|ACCELERATOR-RELEASE-PLAN\.md)[^/]+\.md$/.test(
            relative,
          ) ||
          /^(CHANGELOG|CONTRIBUTING|bn\/CHANGELOG|bn\/CONTRIBUTING)\.md$/.test(
            relative,
          );
        if (!publicDoc)
          return `href=${q}https://github.com/soobujmiah/ternux/blob/main/${relative}${hash}${q}`;
        return `href=${q}${value}.html${hash}${q}`;
      },
    );
}

export type Page = {
  route: string;
  title: string;
  description: string;
  lang: string;
  alt_url?: string;
  source: string;
  html: string;
};
export function getPage(route: string): Page {
  const source = path.join(root, route);
  const raw = fs.readFileSync(source, "utf8");
  const match = raw.match(/^---\s*\n([\s\S]*?)\n---\s*\n/);
  const data: Record<string, string> = {};
  if (match) {
    for (const line of match[1].split(/\r?\n/)) {
      const field = line.match(/^([A-Za-z_][\w-]*):\s*(.*?)\s*$/);
      if (!field) continue;
      const scalar = field[2];
      const wrapped =
        (scalar.startsWith('"') && scalar.endsWith('"')) ||
        (scalar.startsWith("'") && scalar.endsWith("'"));
      data[field[1]] = wrapped ? scalar.slice(1, -1) : scalar;
    }
  }
  const content = match ? raw.slice(match[0].length) : raw;
  const title = String(data.title || path.basename(route, ".md"));
  const description = String(
    data.description || "Ternux technical documentation and device evidence.",
  );
  const html = rewriteHtml(marked.parse(content) as string, route);
  return {
    route,
    title,
    description,
    lang: String(data.lang || (route.startsWith("bn/") ? "bn" : "en")),
    alt_url: data.alt_url,
    source: route,
    html,
  };
}
export function allPages(lang: "en" | "bn") {
  const dir = path.join(root, lang === "bn" ? "bn/docs" : "docs");
  return fs
    .readdirSync(dir)
    .filter(
      (name) => name.endsWith(".md") && !["README.md", "SEO.md"].includes(name),
    )
    .map((name) => getPage(`${lang === "bn" ? "bn/" : ""}docs/${name}`));
}
export function baseUrl(pathname: string) {
  return `${base}${pathname.startsWith("/") ? pathname : `/${pathname}`}`;
}
export function pageUrl(page: Page) {
  const local = page.route
    .replace(/\.md$/, ".html")
    .replace(/^bn\//, "/bn/")
    .replace(/^docs\//, "/docs/");
  return baseUrl(local.startsWith("/") ? local : `/${local}`);
}
