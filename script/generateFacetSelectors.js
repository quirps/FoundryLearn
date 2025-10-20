import fs from "fs";
import path from "path";
import { keccak256, toUtf8Bytes } from "ethers";

const ROOT = path.resolve(__dirname, "..");
const CONFIG_PATH = path.join(ROOT, "config/facets.config.json");
const OUT_DIR = path.join(ROOT, "out");
const OUTPUT_PATH = path.join(ROOT, "facet-selectors.json");

function getSelector(signature) {
  return keccak256(toUtf8Bytes(signature)).slice(0, 10);
}

function main() {
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));
  const facets = config.facets.map((facet) => {
    const artifactPath = path.join(
      OUT_DIR,
      `${facet.subdir}/${facet.name}.sol`,
      `${facet.name}.json`
    );

    if (!fs.existsSync(artifactPath)) {
      throw new Error(`Missing artifact for ${facet.name}: ${artifactPath}`);
    }

    const artifact = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
    const abi = artifact.abi;

    const selectors = abi
      .filter((entry) => entry.type === "function")
      .map((fn) => {
        const sig = `${fn.name}(${fn.inputs.map((i) => i.type).join(",")})`;
        return getSelector(sig);
      });

    return {
      name: facet.name,
      selectors
    };
  });

  const output = { facets };
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(output, null, 2));
  console.log(`✅ Wrote ${facets.length} facet selector sets to ${OUTPUT_PATH}`);
}

main();
