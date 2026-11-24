import { defineConfig } from "astro/config";

export default defineConfig({
  site: "https://soobujmiah.github.io",
  base: "/ternux",
  output: "static",
  build: { format: "file" },
  trailingSlash: "always",
  server: { allowedHosts: [".e2b.app"] },
});
