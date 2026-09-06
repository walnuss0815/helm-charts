'use strict';

// Substitutes `${TOKEN}` placeholders in an Immich config template with values
// taken from the process environment, then writes the resulting file.
//
// Immich reads a single config file verbatim via js-yaml (no built-in env
// expansion), so the substitution must happen before the server starts. This
// script runs inside the chart-managed init container. Every environment
// variable set on the init container is considered: each `${NAME}` placeholder
// found in the template is replaced with the value of that variable, so it is
// the caller's responsibility to keep the container environment scoped to
// exactly the values that should be substituted. The value is YAML-quoted
// before insertion so the resolved file remains valid YAML.
//
// Usage: node substitute.js <template-path> <output-path>

const fs = require('fs');

const args = process.argv.slice(2);
const templatePath = args[0];
const outputPath = args[1];

if (!templatePath || !outputPath) {
  console.error('usage: substitute.js <template-path> <output-path>');
  process.exit(1);
}

let data = fs.readFileSync(templatePath, 'utf8');

for (const [token, value] of Object.entries(process.env)) {
  // JSON.stringify produces a valid double-quoted YAML scalar for the value.
  data = data.split(`\${${token}}`).join(JSON.stringify(value));
}

fs.writeFileSync(outputPath, data);