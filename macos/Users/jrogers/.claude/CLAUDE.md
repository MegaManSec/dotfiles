# Global preferences

## Code comments

Do not add comments that explain or justify a change (why a validation exists, what breaks downstream, why the fix is correct). Rationale belongs in the commit message or PR description, never in the code. Default to zero new comments; write one only when it states a constraint the code cannot express, and match the comment density of the surrounding code.

Never put a comment block above a line when the neighboring, similar lines don't have one. Copy the exact comment style and length of the immediate neighbors: a new field next to fields with short trailing `# ...` comments gets at most an equally short trailing comment, not a multi-line block.

## Pull requests

Keep PR titles and descriptions concise and to-the-point, with only the necessary information.
