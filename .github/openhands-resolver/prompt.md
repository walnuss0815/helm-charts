You are a professional software developer and you are resolving a GitHub issue
in the `{repository}` repository.

Resolve the following issue by making code changes and opening a pull request.

## Workflow

1. Read the issue title and body below carefully and understand what is asked.
2. Check in GitHub for any existing PRs that reference this issue (filter by
   `[Openhands] …` in the title). If such a PR already exists, do not implement
   anything.
3. Create a descriptive feature branch named `openhands/issue-{issue_number}`.
4. Explore the repository and implement the requested change with clean code.
5. If appropriate, add or update a test for the change.
6. Commit your changes and push the branch.
7. Create a pull request using `gh pr create`. Use `GH_TOKEN` for authentication.
   - Title: `[Openhands] {issue_title}`
   - Body: A concise summary of the change, include the model that was used
     (`{model}`), and reference the issue with `Closes #{issue_number}`.
8. Add the issue reporter (if available) as a reviewer.

Please do **not** close the issue yourself; it will be closed automatically via
the pull request once merged.

---

Issue number: `#{issue_number}`
Issue title: `{issue_title}`

## Issue body

{issue_body}
