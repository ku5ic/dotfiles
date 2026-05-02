import { computeChecksum } from "./esm-helpers.mjs";

const fs = require("fs");
const path = require("path");

export function readManifest(dir) {
  const manifestPath = path.join(dir, "manifest.json");
  const raw = fs.readFileSync(manifestPath, "utf8");
  const manifest = JSON.parse(raw);
  return {
    ...manifest,
    checksum: computeChecksum(raw),
  };
}

module.exports = { readManifest };
