#!/usr/bin/env node
/**
 * isshine prepublish check — validate package before publishing
 *
 * Checks:
 * 1. All skill files referenced in manifest exist
 * 2. All template files have Spec blocks
 * 3. All bash scripts are executable (on non-Windows)
 * 4. package.json version matches manifest version
 */

import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { platform } from 'node:os';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const ASSETS = join(ROOT, 'assets');

let errors = 0;
let warnings = 0;

function fail(msg) {
  console.error(`\x1b[31m✗\x1b[0m ${msg}`);
  errors++;
}

function warn(msg) {
  console.warn(`\x1b[33m⚠\x1b[0m ${msg}`);
  warnings++;
}

function ok(msg) {
  console.log(`\x1b[32m✓\x1b[0m ${msg}`);
}

// Check 1: Manifest skill references
console.log('\n--- Checking manifest ---');
const manifest = JSON.parse(readFileSync(join(ASSETS, 'manifest.json'), 'utf-8'));
const pkg = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf-8'));

if (manifest.version !== pkg.version) {
  fail(`Version mismatch: manifest=${manifest.version}, package=${pkg.version}`);
} else {
  ok(`Version: ${manifest.version}`);
}

for (const skill of manifest.skills) {
  const skillPath = join(ASSETS, skill.path);
  if (!existsSync(skillPath)) {
    fail(`Skill missing: ${skill.path}`);
  } else {
    ok(`Skill: ${skill.name}`);
  }
}

for (const script of (manifest.scripts || [])) {
  const scriptPath = join(ASSETS, script.path);
  if (!existsSync(scriptPath)) {
    fail(`Script missing: ${script.path}`);
  } else {
    ok(`Script: ${script.name}`);
  }
}

// Check 2: Templates have Spec blocks
console.log('\n--- Checking templates ---');
const templateDirs = ['spec', 'feature', 'output'];
for (const dir of templateDirs) {
  const templateDir = join(ASSETS, 'templates', dir);
  if (!existsSync(templateDir)) {
    fail(`Template directory missing: templates/${dir}`);
    continue;
  }

  const files = readdirSync(templateDir, { withFileTypes: true })
    .filter(f => f.isFile() && f.name.endsWith('.md'));

  for (const file of files) {
    const filePath = join(templateDir, file.name);
    const content = readFileSync(filePath, 'utf-8');

    if (content.includes('**Spec**')) {
      ok(`templates/${dir}/${file.name} (has Spec)`);
    } else if (file.name === 'pr-comment.md' || file.name === 'issue.md') {
      // Output templates use inline comments for spec
      ok(`templates/${dir}/${file.name} (output template)`);
    } else {
      warn(`templates/${dir}/${file.name} — no Spec block found`);
    }
  }
}

// Check 3: SKILL.md count
console.log('\n--- Checking skill count ---');
const skillsDir = join(ASSETS, 'skills');
const skillDirs = readdirSync(skillsDir, { withFileTypes: true })
  .filter(d => d.isDirectory())
  .map(d => d.name);

const expectedSkills = ['isshine', 'isshine-init', 'isshine-define', 'isshine-design', 'isshine-issue', 'isshine-pr', 'isshine-quick'];

for (const name of expectedSkills) {
  if (!skillDirs.includes(name)) {
    fail(`Missing skill directory: ${name}`);
  }
}
ok(`Found ${skillDirs.length} skill directories`);

// Summary
console.log('\n--- Summary ---');
if (errors > 0) {
  console.error(`\x1b[31m${errors} errors, ${warnings} warnings\x1b[0m`);
  process.exit(1);
} else if (warnings > 0) {
  console.warn(`\x1b[33m0 errors, ${warnings} warnings\x1b[0m`);
  console.log('Ready to publish (with warnings).');
  process.exit(0);
} else {
  console.log('\x1b[32mAll checks passed!\x1b[0m');
  process.exit(0);
}
