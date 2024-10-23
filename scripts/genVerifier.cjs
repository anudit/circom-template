const ejs = require("ejs");
const fs = require("fs");
const process = require("process");

async function exportVerifier() {
  const supportedTemplates = {
    vyper: {
      path: "./templates/verifier.vy.ejs",
      extension: "vy",
    },
    fe: {
      path: "./templates/verifier.fe.ejs",
      extension: "fe",
    },
  };

  let verifierType = process.argv[2].toLowerCase();
  let circuitName = process.argv[3];

  if (Object.keys(supportedTemplates).includes(verifierType)) {
    const VKEY_PATH = `./build/${circuitName}/${circuitName}_vkey.json`;

    let template = String(
      fs.readFileSync(supportedTemplates[verifierType].path),
    );
    let verificationKey = JSON.parse(fs.readFileSync(VKEY_PATH));
    let rendered = ejs.render(template, verificationKey);

    fs.writeFileSync(
      `./build/${circuitName}/${circuitName}_verifer.${supportedTemplates[verifierType].extension}`,
      rendered,
    );
    console.log(`Verifier Generated`);
  } else {
    throw new Error(`Verifier for ${verifierType} not supported.`);
  }
}

exportVerifier();
