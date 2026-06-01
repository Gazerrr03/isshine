#!/usr/bin/env node
/**
 * isshine postinstall — deploy skills to Claude Code skills directory
 *
 * This runs automatically after `npm install` or `npx skills add`.
 * It copies SKILL.md files from assets/skills/ to ~/.claude/skills/isshine*/
 */

import { existsSync, mkdirSync, readFileSync, readdirSync, copyFileSync, statSync, writeFileSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { platform, homedir } from 'node:os';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const ASSETS = join(ROOT, 'assets');
const SKILLS_SRC = join(ASSETS, 'skills');

// Determine Claude Code skills directory
const CLAUDE_SKILLS = join(homedir(), '.claude', 'skills');

function log(msg) {
  console.log(`\x1b[36m[isshine]\x1b[0m ${msg}`);
}

function warn(msg) {
  console.warn(`\x1b[33m[isshine]\x1b[0m ${msg}`);
}

function error(msg) {
  console.error(`\x1b[31m[isshine]\x1b[0m ${msg}`);
}

function deploySkills() {
  if (!existsSync(SKILLS_SRC)) {
    error(`Skills source not found: ${SKILLS_SRC}`);
    return false;
  }

  if (!existsSync(CLAUDE_SKILLS)) {
    mkdirSync(CLAUDE_SKILLS, { recursive: true });
    log(`Created ${CLAUDE_SKILLS}`);
  }

  const skillDirs = readdirSync(SKILLS_SRC, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  let deployed = 0;

  for (const dir of skillDirs) {
    const srcDir = join(SKILLS_SRC, dir);
    const destDir = join(CLAUDE_SKILLS, dir);

    // Create destination directory
    if (!existsSync(destDir)) {
      mkdirSync(destDir, { recursive: true });
    }

    // Copy all files recursively
    copyRecursive(srcDir, destDir);
    deployed++;
    log(`Deployed: ${dir} → ${destDir}`);
  }

  log(`Deployed ${deployed} skills to ${CLAUDE_SKILLS}`);
  return true;
}

function copyRecursive(src, dest) {
  const entries = readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = join(src, entry.name);
    const destPath = join(dest, entry.name);

    if (entry.isDirectory()) {
      if (!existsSync(destPath)) {
        mkdirSync(destPath, { recursive: true });
      }
      copyRecursive(srcPath, destPath);
    } else {
      copyFileSync(srcPath, destPath);
    }
  }
}

// Show banner
function showBanner() {
  const pkg = JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf-8'));
  console.log('');
  console.log(`  \x1b[1m\x1b[33m⚡ isshine\x1b[0m \x1b[2mv${pkg.version}\x1b[0m  —  flash of requirement`);
  console.log('');
  console.log('  Generate AI-friendly, human-readable GitHub Issues');
  console.log('  from conversations. One conversation = one Issue.');
  console.log('');
  console.log('  \x1b[1mQuick start:\x1b[0m');
  console.log('    \x1b[36m/isshine-init\x1b[0m     Set up project spec/ and strategies');
  console.log('    \x1b[36m/isshine\x1b[0m           Start a new requirement');
  console.log('    \x1b[36m/isshine-quick\x1b[0m     Quick mode (skip deep design)');
  console.log('    \x1b[36m/isshine-pr\x1b[0m        Generate PR comment from artifacts');
  console.log('');
}

// Main
try {
  showBanner();
  deploySkills();
  log('Done! Ready to use /isshine in Claude Code.');
} catch (err) {
  error(`Postinstall failed: ${err.message}`);
  // Don't fail the install — the package is still usable
  process.exit(0);
}
