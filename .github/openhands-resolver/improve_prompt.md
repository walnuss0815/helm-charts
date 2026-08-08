You are improving the existing pull request `#{pr_number}` in the `{repository}`
repository. The pull request was created automatically to resolve an issue, and
you are now asked to improve it based on the current pull request content and
all of its comments.

## Current pull request

Number: `#{pr_number}`
Title: `{pr_title}`
Current head branch: `{head_ref}`

### Pull request body

{pr_body}

## Comments on the pull request

{pr_comments}

## CI status for the latest commit

These are the CI check runs, annotations and error messages associated with the
latest commit of this pull request. Fix any CI failures caused by your changes.

{ci_logs}

## Workflow

1. Read the pull request title, body, and all comments carefully to understand
   the requested improvements and any reviewer feedback.
2. Carefully inspect the CI section above. If any checks failed, fix the root
   cause of the failures along with the requested improvements.
3. Work on the existing PR branch (`{head_ref}`) which is already checked out —
   do **not** create a new branch or a new pull request.
4. Implement the requested improvements with clean code, addressing the feedback
   found in the comments where applicable.
5. If appropriate, add or update tests for the changes.
6. Commit your changes and push them to `{head_ref}` using `gh`/`git`. Use
   `GH_TOKEN` for authentication.
7. Update the pull request body/description if it is no longer accurate. Do
   **not** close the pull request.

Do not commit any helper or metadata files (e.g. `*.json`) unless they are part
of the repository's intended content.

Model used: `{model}`
