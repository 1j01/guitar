const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const isWorkingDirectoryClean = () => {
	try {
		execSync('git update-index --really-refresh -q');
		execSync('git diff --quiet HEAD --');
		execSync('git diff-index --quiet HEAD --');
		// Handle untracked files
		const output = execSync('git status --porcelain').toString();
		const untrackedRegex = /^\?\?/m;
		return !untrackedRegex.test(output);
	} catch (error) {
		return false;
	}
};

const predeploy = () => {
	if (!isWorkingDirectoryClean()) {
		console.error('Working directory is not clean. Please commit or stash your changes before deploying.');
		process.exit(1);
	}

	// Note: this doesn't work for @scoped packages, or packages not at node_modules root.
	// I could use https://www.npmjs.com/package/npm-link-check for a more robust solution.
	const nodeModulesPath = './node_modules';
	const moduleNames = fs.readdirSync(nodeModulesPath);
	for (const moduleName of moduleNames) {
		const modulePath = path.join(nodeModulesPath, moduleName);
		const stats = fs.lstatSync(modulePath);
		if (stats.isSymbolicLink()) {
			console.error(`${moduleName} is npm-linked, please unlink and test before deploying.`);
			process.exit(1);
		}
	}
};

predeploy();
