#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const templateRoot = path.join(
  projectRoot,
  'node_modules',
  'react-native',
  'template'
);

if (!fs.existsSync(templateRoot)) {
  console.error(
    'Unable to locate the React Native template files. Make sure dependencies are installed with `npm install` first.'
  );
  process.exit(1);
}

const copyTargets = [
  'android',
  'ios',
  'Gemfile',
  'Gemfile.lock',
  '.ruby-version'
];

const copyOptions = { recursive: true, force: false, errorOnExist: false };

copyTargets.forEach((relativePath) => {
  const sourcePath = path.join(templateRoot, relativePath);
  const destinationPath = path.join(projectRoot, relativePath);

  if (!fs.existsSync(sourcePath)) {
    return;
  }

  if (fs.existsSync(destinationPath)) {
    console.log(`Skipping ${relativePath}; destination already exists.`);
    return;
  }

  fs.cpSync(sourcePath, destinationPath, copyOptions);
  console.log(`Copied ${relativePath} from React Native template.`);
});

console.log('Native scaffolding ready. Remember to run `cd ios && pod install` before opening the workspace in Xcode.');
