import { build, context } from "esbuild";
import { cp, mkdir, rm } from "node:fs/promises";

const watch = process.argv.includes("--watch");
const staticFiles = ["manifest.json"];

async function copyStaticFiles() {
  await mkdir("dist", { recursive: true });
  await Promise.all(staticFiles.map((file) => cp(`src/${file}`, `dist/${file}`)));
}

const options = {
  entryPoints: {
    background: "src/background.ts",
    content: "src/content.ts"
  },
  bundle: true,
  format: "esm",
  outdir: "dist",
  sourcemap: true,
  target: "chrome138",
  logLevel: "info"
};

await rm("dist", { recursive: true, force: true });
await copyStaticFiles();

if (watch) {
  const buildContext = await context(options);
  await buildContext.watch();
  console.log("Watching source files. Reload the extension after each rebuild.");
} else {
  await build(options);
}
