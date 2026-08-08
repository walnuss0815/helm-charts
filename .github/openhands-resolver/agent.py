#!/usr/bin/env python3
"""
OpenHands Issue Resolver.

Two modes:
  * --issue <N>  Resolve a GitHub issue, creating a new pull request.
  * --pr <N>     Improve an existing pull request based on its title, body,
                 all comments and the CI results for its latest commit.

Add --dry-run to run as a local test: GitHub data is still READ (issue/PR/comments/
CI) so the prompts work, but the agent is instructed not to push, commit, create/update
PRs or issues, or otherwise modify any GitHub or git state.

GitHub data is fetched through the PyGithub library using the GH_TOKEN. The `gh`
CLI remains available in the environment for the git / pull-request operations
performed by the agent.

The prompt for each mode is templated from a Markdown file residing next to this
script (`prompt.md` / `improve_prompt.md`).
"""

import argparse
import os
import sys
from pathlib import Path

from github import Github, UnknownObjectException

from openhands.sdk import LLM, Conversation, get_logger
from openhands.tools.preset.default import get_default_agent


logger = get_logger(__name__)

BASE_DIR = Path(__file__).resolve().parent
RESOLVE_PROMPT_PATH = BASE_DIR / "prompt.md"
IMPROVE_PROMPT_PATH = BASE_DIR / "improve_prompt.md"

DEFAULT_MODEL = "openrouter/openrouter/free"

DRY_RUN_NOTE = """
## LOCAL TEST / DRY RUN MODE (IMPORTANT - READ FIRST)

You are running as a LOCAL TEST. Do NOT perform any write operation on GitHub
or on git:

- Do NOT create or push any branch, and do NOT `git commit`, `git push`, or
  `git tag`.
- Do NOT create, update, or close any GitHub issue or pull request.
- Do NOT add reviewers, post comments, or run any `gh`/API command that changes
  remote state.

Instead, implement the requested change in the local working tree ONLY, and at
the end clearly summarize:

- which files you changed and how,
- what the resulting diff would look like,
- the pull request title/description you would have created (if any), and
- any CI failures you addressed.

This is a test: nothing will be committed, pushed, or published.
"""


def build_llm() -> tuple[LLM, str]:
    api_key = os.getenv("LLM_API_KEY")
    if not api_key:
        logger.error("LLM_API_KEY environment variable is not set.")
        sys.exit(1)

    model = os.getenv("LLM_MODEL", DEFAULT_MODEL)
    base_url = os.getenv("LLM_BASE_URL")

    llm_config = {
        "model": model,
        "api_key": api_key,
        "drop_params": True,
    }
    if base_url:
        llm_config["base_url"] = base_url

    return LLM(**llm_config), model


def get_github() -> Github:
    token = os.getenv("GH_TOKEN")
    if not token:
        logger.error("GH_TOKEN environment variable is not set.")
        sys.exit(1)
    return Github(token)


def get_repository(gh: Github):
    repository = os.getenv("GITHUB_REPOSITORY", "")
    return gh.get_repo(repository)


def run_agent(prompt: str, llm: LLM) -> None:
    cwd = os.getcwd()
    agent = get_default_agent(llm=llm, cli_mode=True)
    conversation = Conversation(agent=agent, workspace=cwd)

    logger.info("Starting task execution...")
    conversation.send_message(prompt)
    conversation.run()

    logger.info("Agent task completed.")


def build_issue_prompt(issue_number: int, model: str, dry_run: bool = False) -> str:
    gh = get_github()
    issue = get_repository(gh).get_issue(issue_number)

    title = issue.title or ""
    if not title:
        logger.error("Issue title is empty.")
        sys.exit(1)

    prompt = RESOLVE_PROMPT_PATH.read_text().format(
        repository=os.getenv("GITHUB_REPOSITORY", ""),
        model=model,
        issue_number=issue_number,
        issue_title=title,
        issue_body=issue.body or "",
    )
    if dry_run:
        prompt = DRY_RUN_NOTE + "\n\n" + prompt
    return prompt


def author_of(user) -> str:
    return user.login if user is not None else "unknown"


def build_ci_sections(repo, pr) -> str:
    sections = []

    try:
        check_runs = list(repo.get_commit(pr.head.sha).get_check_runs())
    except UnknownObjectException:
        return "_No CI results found for the latest commit._"

    if check_runs:
        lines = []
        for run in check_runs:
            app = getattr(run, "app", None)
            app_name = (
                getattr(app, "name", None)
                or getattr(app, "slug", None)
                or getattr(app, "login", None)
                or "unknown"
            )
            lines.append(
                f"- **{run.name}** ({app_name}): "
                f"status={run.status}, conclusion={run.conclusion}"
            )
            output = run.output
            if output is not None:
                if output.title:
                    lines.append(f"  title: {output.title}")
                if output.summary:
                    lines.append(f"  summary: {output.summary}")
                if output.text:
                    lines.append(f"  output:\n{output.text}")
        sections.append("### CI check runs (latest commit)\n" + "\n".join(lines))

        annotation_lines = []
        for run in check_runs:
            try:
                for a in run.get_annotations():
                    location = f"{a.path}:{a.start_line}" if a.path else "-"
                    annotation_lines.append(
                        f"- [{a.annotation_level}] {location} {a.title or ''}: "
                        f"{(a.message or '').strip()}"
                    )
            except UnknownObjectException:
                continue
        if annotation_lines:
            sections.append(
                "### CI annotations / errors\n" + "\n".join(annotation_lines)
            )

    if not sections:
        return "_No CI results found for the latest commit._"

    return "\n\n".join(sections)


def build_pr_prompt(pr_number: int, model: str, dry_run: bool = False) -> str:
    gh = get_github()
    repo = get_repository(gh)
    pr = repo.get_pull(pr_number)

    comments = []
    for comment in pr.get_review_comments():
        comments.append((author_of(comment.user), comment.body or ""))
    for comment in pr.get_issue_comments():
        comments.append((author_of(comment.user), comment.body or ""))

    comments_text = "\n\n".join(
        f"**{author}:** {body}" for author, body in comments
    )
    if not comments_text:
        comments_text = "_No comments yet._"

    prompt = IMPROVE_PROMPT_PATH.read_text().format(
        repository=os.getenv("GITHUB_REPOSITORY", ""),
        model=model,
        pr_number=pr_number,
        pr_title=pr.title or "",
        pr_body=pr.body or "_No body._",
        head_ref=pr.head.ref,
        pr_comments=comments_text,
        ci_logs=build_ci_sections(repo, pr),
    )
    if dry_run:
        prompt = DRY_RUN_NOTE + "\n\n" + prompt
    return prompt


def resolve_issue(issue_number: int, llm: LLM, model: str, dry_run: bool) -> None:
    run_agent(build_issue_prompt(issue_number, model, dry_run), llm)


def improve_pr(pr_number: int, llm: LLM, model: str, dry_run: bool) -> None:
    run_agent(build_pr_prompt(pr_number, model, dry_run), llm)


def main():
    parser = argparse.ArgumentParser(description="Resolve GitHub issues / improve PRs using OpenHands")
    parser.add_argument("--issue", type=int, help="GitHub issue number to resolve")
    parser.add_argument("--pr", type=int, help="GitHub pull request number to improve")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Local test: read GitHub data but never write to GitHub or git.",
    )
    args = parser.parse_args()

    if not args.issue and not args.pr:
        parser.error("Provide either --issue <N> or --pr <N>")

    llm, model = build_llm()

    if args.issue:
        resolve_issue(args.issue, llm, model, args.dry_run)
    else:
        improve_pr(args.pr, llm, model, args.dry_run)


if __name__ == "__main__":
    main()
