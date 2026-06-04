#!/usr/bin/env node
/**
 * isshine postinstall — deploy skills to Claude Code skills directory
 *
 * This runs automatically after `npm install` or `npx skills add`.
 * It copies SKILL.md files from assets/skills-zh/ to ~/.claude/skills/isshine*.
 */

import { existsSync, mkdirSync, readFileSync, readdirSync, copyFileSync, statSync, writeFileSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { platform, homedir } from 'node:os';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const ASSETS = join(ROOT, 'assets');
const DEFAULT_LOCALE = 'zh';
const SKILLS_SRC = join(ASSETS, DEFAULT_LOCALE === 'zh' ? 'skills-zh' : 'skills');
const FALLBACK_SKILLS_SRC = join(ASSETS, 'skills');

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
  const skillsSource = existsSync(SKILLS_SRC) ? SKILLS_SRC : FALLBACK_SKILLS_SRC;
  if (!existsSync(skillsSource)) {
    error(`Skills source not found: ${skillsSource}`);
    return false;
  }

  if (skillsSource !== SKILLS_SRC) {
    warn(`Default ${DEFAULT_LOCALE} skills not found; falling back to ${relative(ROOT, skillsSource)}`);
  }

  if (!existsSync(CLAUDE_SKILLS)) {
    mkdirSync(CLAUDE_SKILLS, { recursive: true });
    log(`Created ${CLAUDE_SKILLS}`);
  }

  const skillDirs = readdirSync(skillsSource, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  let deployed = 0;

  for (const dir of skillDirs) {
    const srcDir = join(skillsSource, dir);
    const destDir = join(CLAUDE_SKILLS, dir);

    // Create destination directory
    if (!existsSync(destDir)) {
      mkdirSync(destDir, { recursive: true });
    }

    // Copy all files recursively
    copyRecursive(srcDir, destDir);

    if (dir === 'isshine') {
      const scriptsSrc = join(FALLBACK_SKILLS_SRC, 'isshine', 'scripts');
      const scriptsDest = join(destDir, 'scripts');
      if (existsSync(scriptsSrc)) {
        if (!existsSync(scriptsDest)) {
          mkdirSync(scriptsDest, { recursive: true });
        }
        copyRecursive(scriptsSrc, scriptsDest);
      }
    }

    deployed++;
    log(`Deployed: ${dir} → ${destDir}`);
  }

  log(`Deployed ${deployed} ${DEFAULT_LOCALE} skills to ${CLAUDE_SKILLS}`);
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
  console.log('  将对话转化为 AI 友好、人类可读的 GitHub Issue');
  console.log('  默认安装中文 skill；一个对话 = 一个 Issue。');
  console.log('');
  console.log('  \x1b[1m快速开始:\x1b[0m');
  console.log('    \x1b[36m/isshine-init\x1b[0m     设置项目 spec/ 和处理策略');
  console.log('    \x1b[36m/isshine\x1b[0m           开始一个新需求');
  console.log('    \x1b[36m/isshine-quick\x1b[0m     快速模式（跳过深度设计）');
  console.log('    \x1b[36m/isshine-pr\x1b[0m        基于产物生成 PR comment');
  console.log('');
}

// Main
try {
  showBanner();
  deploySkills();
  log('完成！现在可以在 Claude Code 中使用 /isshine。');
} catch (err) {
  error(`Postinstall failed: ${err.message}`);
  // Don't fail the install — the package is still usable
  process.exit(0);
}
