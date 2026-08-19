import { mkdir, rm } from "node:fs/promises";
import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";

const { version } = JSON.parse(await readFile("package.json", "utf8"));
const artifact = `artifacts/kotoba-lens-v${version}.zip`;

await mkdir("artifacts", { recursive: true });
await rm(artifact, { force: true });

await new Promise((resolve, reject) => {
  const zip = spawn("zip", ["-qr", `../${artifact}`, "."], {
    cwd: "dist",
    stdio: "inherit"
  });
  zip.once("error", reject);
  zip.once("exit", (code) => {
    if (code === 0) resolve();
    else reject(new Error(`zip exited with code ${code}`));
  });
});

console.log(`Created ${artifact}`);
