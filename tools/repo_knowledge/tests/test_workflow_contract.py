"""Protect repository state sync from bypassing the main branch rules."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
WORKFLOW = ROOT / ".github/workflows/repo-knowledge-sync.yml"


class RepoKnowledgeWorkflowContractTests(unittest.TestCase):
    def test_state_updates_use_a_pr_and_approve_only_its_expected_checks(self):
        workflow = WORKFLOW.read_text()
        import yaml
        parsed = yaml.safe_load(workflow)
        self.assertEqual(parsed["permissions"], {"contents": "read"})
        self.assertEqual(parsed["jobs"]["sync"]["permissions"], {"contents": "read"})
        self.assertEqual(
            parsed["jobs"]["publish_state"]["permissions"],
            {"actions": "write", "contents": "write", "pull-requests": "write"},
        )
        self.assertIn("uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7", workflow)
        self.assertIn("include-hidden-files: true", workflow)
        self.assertIn("uses: actions/download-artifact@9000827ccba6bdab643e8b6fd33ac0654aef8333 # v8", workflow)
        self.assertIn("uses: peter-evans/create-pull-request@3ffccacd46053766916f087ce41d627c0b8cf2d1 # v8", workflow)
        self.assertIn("add-paths: .repo/", workflow)
        self.assertIn("pull-requests: write", workflow)
        self.assertIn("actions: write", workflow)
        self.assertIn("name: Approve checks for generated state pull request", workflow)
        self.assertIn('gh api -X POST "repos/$GITHUB_REPOSITORY/actions/runs/$run_id/approve"', workflow)
        self.assertIn('gh api "repos/$GITHUB_REPOSITORY/actions/runs?per_page=100"', workflow)
        self.assertNotIn('--paginate', workflow)
        self.assertNotIn('branch=$STATE_BRANCH&event=pull_request', workflow)
        self.assertIn('select(.head_sha == $sha and .head_branch == $branch and .conclusion == "action_required"', workflow)
        for expected_workflow in ("Validate", "Repository State Contract", "Termux APT package artifact", "Repo Knowledge Sync"):
            self.assertIn(f'\"{expected_workflow}\"', workflow)
        self.assertNotIn("git push origin HEAD:", workflow)


if __name__ == "__main__":
    unittest.main()
