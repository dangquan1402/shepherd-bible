"""content_summary.display_order must match QuizRules.displayOrder in the app.

python3 -I -m unittest discover -s tools/content -v
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import content_summary as cs


class DisplayOrderPort(unittest.TestCase):
    def test_matches_the_values_pinned_in_ContentTests_swift(self):
        # ShepherdTests/ContentTests.swift testChoiceOrderIsAStablePermutation pins these.
        self.assertEqual(cs.display_order({"id": "day1-q1", "choices": list("abcd")}), [3, 2, 1, 0])
        self.assertEqual(cs.display_order({"id": "peace-14.d01.q2", "choices": list("abcd")}), [1, 2, 0, 3])


if __name__ == "__main__":
    unittest.main()
