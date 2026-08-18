import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer } from "node:http";
import { extname, join, normalize } from "node:path";

const root = process.cwd();
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".map": "application/json" };

createServer(async (request, response) => {
  const pathname = new URL(request.url ?? "/", "http://127.0.0.1").pathname;
  const relative = pathname === "/" ? "qa/preview.html" : pathname.replace(/^\/+/, "");
  const path = normalize(join(root, relative));
  if (!path.startsWith(root)) {
    response.writeHead(403).end();
    return;
  }
  try {
    const info = await stat(path);
    if (!info.isFile()) throw new Error("not a file");
    response.writeHead(200, { "Content-Type": types[extname(path)] ?? "application/octet-stream" });
    createReadStream(path).pipe(response);
  } catch {
    response.writeHead(404).end("Not found");
  }
}).listen(4173, "127.0.0.1", () => console.log("QA preview: http://127.0.0.1:4173"));
