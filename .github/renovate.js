module.exports = {
  dryRun: "full",
  username: "renovate-release",
  gitAuthor: "Renovate Bot <bot@walnuss0815.de>",
  onboarding: false,
  platform: "github",
  packageRules: [
    {
      matchManagers: ["github-actions"],
      groupName: "github actions",
      dependencyDashboardApproval: false,
      minimumReleaseAge: "1 day"
    }
  ],
};
