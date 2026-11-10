"""Protect repository state sync from bypassing the main branch rules."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
WORKFLOW = ROOT / ".github/workflows/repo-knowledge-sync.yml"


class RepoKnowledgeWorkflowContractTests(unittest.TestCase):
    def test_state_updates_use_a_pr_and_dispatch_required_checks(self):
        workflow = WORKFLOW.read_text()
        self.assertIn("uses: peter-evans/create-pull-request@v7", workflow)
        self.assertIn("add-paths: .repo/", workflow)
        self.assertIn("pull-requests: write", workflow)
        self.assertIn("actions: write", workflow)
        self.assertIn(
            "for workflow in ci.yml repo-contract.yml termux-apt-package.yml repo-knowledge-sync.yml; do",
            workflow,
        )
        self.assertNotIn("git push origin HEAD:", workflow)


if __name__ == "__main__":
    unittest.main()
