module.exports = {
  extends: ['config:recommended'],
  dryRun: 'full',
  username: 'renovate-release',
  repositories: ['walnuss0815/helm-charts'],
  gitAuthor: 'Renovate Bot <bot@renovateapp.com>',
  onboarding: false,
  platform: 'github',
  packageRules: [
    {
      matchManagers: ['github-actions'],
      groupName: 'github actions',
      dependencyDashboardApproval: false,
      minimumReleaseAge: '1 day',
    },
  ],
};
