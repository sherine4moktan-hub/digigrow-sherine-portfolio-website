import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dist = path.join(project, "dist");
const required = [
  "index.html", "about/index.html", "services/index.html", "blog/index.html", "contact/index.html",
  "blog/how-ai-can-help-small-business-marketing/index.html",
  "blog/build-a-digital-marketing-plan/index.html",
  "blog/turn-website-visitors-into-qualified-leads/index.html",
  "assets/styles.css", "assets/app.js", "assets/site-data.js", "robots.txt", "sitemap.xml"
];
const errors = [];

for (const rel of required) {
  try { await fs.access(path.join(dist, rel)); } catch { errors.push(`Missing: ${rel}`); }
}

const htmlFiles = required.filter((f) => f.endsWith(".html"));
for (const rel of htmlFiles) {
  const html = await fs.readFile(path.join(dist, rel), "utf8");
  for (const token of ["<title>", 'name="description"', "<main", "skip-link", "site-header", "site-footer"]) {
    if (!html.includes(token)) errors.push(`${rel}: missing ${token}`);
  }
  if (!html.includes("Book a Free Consultation Call")) errors.push(`${rel}: missing primary CTA`);
}

const allFiles = await Promise.all(htmlFiles.map(async (rel) => ({ rel, html: await fs.readFile(path.join(dist, rel), "utf8") })));
for (const { rel, html } of allFiles) {
  const links = [...html.matchAll(/href="(\/[^"]+)"/g)].map((m) => m[1].split(/[?#]/)[0]);
  for (const href of links) {
    if (!href || href.includes(".")) continue;
    const target = href === "/" ? "index.html" : `${href.replace(/^\//, "").replace(/\/$/, "")}/index.html`;
    try { await fs.access(path.join(dist, target)); } catch { errors.push(`${rel}: broken internal route ${href}`); }
  }
}

if (errors.length) {
  console.error(`Validation failed (${errors.length}):\n- ${errors.join("\n- ")}`);
  process.exit(1);
}
console.log(`Validation passed: ${required.length} required files and ${htmlFiles.length} page routes checked.`);
