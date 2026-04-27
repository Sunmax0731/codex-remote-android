import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import assert from "node:assert/strict";
import { resultImagePaths } from "../src/lib/resultAttachmentPublisher.js";

test("resultImagePaths extracts readable markdown image references", async () => {
  const tempRoot = await mkdtemp(join(tmpdir(), "codex-result-image-test-"));
  const imagePath = join(tempRoot, "result.png");
  await writeFile(imagePath, Buffer.from([0x89, 0x50, 0x4e, 0x47]));

  const paths = await resultImagePaths(`done\n\n![result](result.png)`, tempRoot);

  assert.deepEqual(paths, [imagePath]);
});

test("resultImagePaths ignores remote and non-image references", async () => {
  const tempRoot = await mkdtemp(join(tmpdir(), "codex-result-image-test-"));
  await writeFile(join(tempRoot, "notes.txt"), "hello");

  const paths = await resultImagePaths(
    [
      "![remote](https://example.com/result.png)",
      "![data](data:image/png;base64,AAAA)",
      "![text](notes.txt)",
      "![missing](missing.png)",
    ].join("\n"),
    tempRoot,
  );

  assert.deepEqual(paths, []);
});
