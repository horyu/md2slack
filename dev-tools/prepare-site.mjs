import { copyFileSync, mkdirSync } from "node:fs";

const output = new URL("../docs/", import.meta.url);
mkdirSync(output, { recursive: true });
copyFileSync(new URL("../web/index.html", import.meta.url), new URL("index.html", output));
copyFileSync(
  new URL("../_build/wasm-gc/debug/build/web/wasm/wasm.wasm", import.meta.url),
  new URL("app.wasm", output),
);
