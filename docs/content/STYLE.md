# Lesson style guide

How to write a lesson path for the app. The three launch paths (`beginner-30`, `peace-14`, `mark-30` in `Shepherd/Resources/Content/paths.json`) follow it; use them as worked examples.

## 1. Non-negotiables

1. **Scripture is never typed from memory.** Every verse reference, every quotation in the prose, every fill-in-the-blank prompt and every quiz answer comes verbatim from the bundled `web.json` (World English Bible, eBible `engwebp`, "LORD" edition). Pull the text with a script, copy it, and let the validator prove it.
2. **The validator passes with 0 errors**, including `--release` for anything that ships:
   ```
   python3 -I tools/content/validate_content.py --release
   python3 -I -m unittest discover -s tools/content
   ```
3. **Original copy only.** Never paraphrase, adapt or "summarise" a study Bible, devotional, commentary or sermon. Read the passage and write what you see.
4. **No AI or chatbot framing** in the copy ("As an AI…", "Let's explore…", "In today's fast-paced world…").
5. **Never use the app's name in lesson copy** (titles, bodies, prayers, quizzes). Say "this app" or "the Bible tab" if you must refer to it; the name can change, the lessons should not.
6. **Lesson ids are permanent.** Progress is keyed by lesson id alone; never rename or reuse one. New lessons use `<path-id>.dNN`, questions `<lesson-id>.qN`.

## 2. Voice

- **Plain, warm, adult.** Short sentences. Second person ("you") for the reader; no "we must".
- **Describe before you apply.** Say what the passage says and notice one thing in it; only then invite a response.
- **Show the text, don't preach it.** Prefer "Jesus doesn't keep away from people with a bad name" to "God wants you to welcome everyone".
- **US spelling**, to match the WEB text (neighbor, honor, center).
- **Typography.** Quote Scripture with straight double quotes `"…"` in the JSON so the validator can check it; the quoted text keeps WEB's own curly apostrophes and inner quotes (`"Don’t be afraid"`). The app turns straight quotes and apostrophes into typographic ones when it displays them (`LessonText.curlyQuotes`), so your own copy uses straight ones too. Glosses and word meanings are not quotations: write *save us* or plain words, never quote marks.
- **Avoid**: clichés ("journey", "unpack", "lean in", "season of life"), exclamation marks in our own voice, emoji, rhetorical questions stacked in a row, "simply" about hard things.

## 3. Lesson anatomy (the 5-minute core)

| Part | Field | Target |
|---|---|---|
| Title | `title` | ≤ 5 words, concrete ("The father runs", "Lie down in peace"). |
| Read | `verseRefs` | 2–5 verses, about 50–130 words of Scripture. Consecutive where possible; a non-consecutive selection is fine when it tells the story (each verse is its own card). |
| Understand | `bodyMarkdown`, paragraphs 1–2 | 100–170 words. What happens or what is said, plus one observation. Quote the key line verbatim. |
| Reflection | `bodyMarkdown`, `**Reflection:**` paragraph | 1–2 sentences, one open question about the reader's own life. Never a test of knowledge. |
| Study aid | `bodyMarkdown`, last paragraph in `*italics*` starting `Study aid:` | Optional, ≤ 40 words. One background fact, with a checkable citation ("(Leviticus 13:46)"). Hedge where scholars differ. |
| Pray | `prayerPrompt` | 1–2 sentences, first person, invitational. The reader can pray it or use their own words. |
| Quiz | `quiz` | 3 questions (2 is acceptable), see §4. |

Whole lesson body: about 140–200 words. A path's lessons should feel the same length; the summary script shows the spread.

Background the text does not show (earlier events, other books) is fine, but cite it: "(Luke 15:13)". The validator checks every cited reference exists and every quotation is verbatim from the lesson or a cited verse.

## 4. Quiz questions

- **Test understanding of the passage shown**, not memory of trivia. Good: "Why did the man go away sorrowful?" Weak: "How many denarii…?"
- **Mix the types:** fill-in-the-blank from a verse (`"Love is ___ and is kind."`), comprehension ("What did Jesus do before he spoke the words of healing?"), and "what did X say/do". Usually no more than one fill-in-the-blank per lesson.
- **Interactive types:** about 1 in 5 questions per path may use a non-choice type (`fill_blank`, `order`, `true_false`, `match`; shapes below). Never two non-choice questions in a row in a lesson (the validator fails it). Use one where it tests the lesson's own point, never just to fill the quota.
- **Don't give away a later answer.** A question's visible text (prompt, word bank, tokens, pair texts) must not contain the answer to a later question in the same lesson; the validator warns. Prefer a verse no other question tests.
- **Every question has an `answerRef`** (one of the lesson's `verseRefs`) whose text contains the correct choice verbatim (case-insensitive), and an `explain` that cites it ("Mark 1:41: …"). The app shows that verse as the proof.
- **Quotation marks mean WEB text.** Anything in `"…"` in a prompt or `explain` is checked against the lesson's verses, including a span that nests the verse's own `“…”`. Paraphrase without quotation marks.
- **Exactly one defensible answer.** Distractors are plausible but clearly wrong from the passage. Don't use a distractor that is a true statement elsewhere in the same verses (the validator warns for `choice`), and avoid ones that are true in a parallel passage ("strength" for Matthew 22:37, which Mark 12:30 has).
- **Never mock.** No joke choices ("Wallet", "Chance"), nothing that makes a person or group look stupid.
- **No doctrine in an answer.** Quiz only what the verses say, never a tradition's reading of them.
- **Answer position.** Write the answer and three wrong choices; the authoring step places the answer so positions are balanced across a path, both as authored (`correctIndex`) and as displayed (`QuizRules.displayOrder` shuffles by question id). Check with `tools/content/content_summary.py`.
- Keep choices short and parallel in form (all phrases, or all single words).

### Exercise types and JSON shapes

The ids below are made up; real ids are lesson-scoped (`mark-30.d05.q2`). `type` defaults to `choice`.

1. **`choice`**: multiple choice.
   ```json
   {
     "id": "example.q1",
     "prompt": "What were Simon and Andrew doing when Jesus saw them?",
     "choices": ["mending their nets", "casting a net into the sea", "selling fish", "praying on the shore"],
     "correctIndex": 1,
     "answerRef": "MRK.1.16",
     "explain": "Mark 1:16: \"casting a net into the sea, for they were fishermen.\""
   }
   ```

2. **`fill_blank`**: a short lead-in, then the verse in quotation marks with `___` inside them. The app shows the lead-in as the title and the quoted verse once, in a card. The blank filled with the answer must be verbatim WEB text.
   ```json
   {
     "id": "example.q2",
     "type": "fill_blank",
     "prompt": "Complete the verse: \"For my yoke is easy, and my burden is ___.\"",
     "choices": ["light", "heavy", "small", "removed"],
     "correctIndex": 0,
     "answerRef": "MAT.11.30",
     "explain": "Matthew 11:30: \"For my yoke is easy, and my burden is light.\""
   }
   ```

3. **`order`**: `orderTokens` in the correct order; joined with spaces they must be a verbatim substring of the `answerRef` verse. Use at least three tokens (two is a coin flip).
   ```json
   {
     "id": "example.q3",
     "type": "order",
     "prompt": "Put Jesus’ words in order:",
     "orderTokens": ["Come after me,", "and I will make you", "into fishers for men."],
     "answerRef": "MRK.1.17",
     "explain": "Mark 1:17: Jesus said, \"Come after me, and I will make you into fishers for men.\""
   }
   ```

4. **`true_false`**: a statement about the verses; `choices` is `["True", "False"]`, `correctIndex` 0 for True, 1 for False. A false statement should be a plausible misreading, not a straw man.
   ```json
   {
     "id": "example.q4",
     "type": "true_false",
     "prompt": "During the storm, Jesus was awake at the front of the boat.",
     "choices": ["True", "False"],
     "correctIndex": 1,
     "answerRef": "MRK.4.38",
     "explain": "Mark 4:38: \"He himself was in the stern, asleep on the cushion.\""
   }
   ```

5. **`match`**: `pairs` of `{ "ref", "text" }`; each ref is one of the lesson's verses and each text is verbatim from it. The app numbers each reference and shows that number on the verse it is matched to; a wrong answer lists every correct pair.
   ```json
   {
     "id": "example.q5",
     "type": "match",
     "prompt": "Match each reference to Jesus’ words:",
     "pairs": [
       { "ref": "MRK.1.17", "text": "I will make you into fishers for men." },
       { "ref": "MRK.1.41", "text": "I want to. Be made clean." }
     ],
     "answerRef": "MRK.1.17",
     "explain": "Mark 1:17 and Mark 1:41: Jesus calls fishermen and heals a man with leprosy."
   }
   ```

## 5. Theology: non-denominational and mainstream

- Say what the text says, with references. Do not assert one tradition's reading on baptism, communion, end times, spiritual gifts, election, Mary, saints, or the canon.
- When readings differ, say so plainly: "Christians understand this meal in different ways", "Many readers see…", "Scholars discuss…".
- Frame study aids as aids, not doctrine. Interpretive claims are attributed ("Many Christians understand…"), never "God wants you to…" beyond what the verse says.
- Faith statements central to all mainstream Christian traditions (creation, the incarnation, the cross, the resurrection) may be stated as what Christians believe, anchored to the text.
- Prayer prompts are invitations, not formulas or promises of outcomes.

## 6. Sensitive topics

| Topic | Do | Don't |
|---|---|---|
| Anxiety, low mood, despair | Treat lament as faithful prayer. Where a lesson is about worry or despair, add a short plain note that seeing a doctor or counselor is wise and not a failure of faith; for despair, add "If you are thinking of harming yourself, contact your local emergency number or a crisis line now." (see `peace-14.d04`, `peace-14.d06`) | Imply worry is sin or that enough faith removes it. |
| Forgiveness | Say forgiving is often a process and not the same as excusing harm or staying unsafe (see `beginner-30.d23`). | Pressure a reader to reconcile with someone who hurts them. |
| Infertility, illness, loss | Say plainly that the passage does not promise the same outcome to everyone (see `peace-14.d08`). | Turn a healing or answered prayer into a guarantee. |
| Money and giving | Invite generosity with time, attention or money as trust. | Ask for money, or tie blessing to giving. |
| Death, the cross, suffering | Let the text be heavy; end with the text's own hope. | Hurry past grief with a slogan. |
| Spiritual oppression, disability in healing stories | Keep the focus on the person and Jesus' compassion. | Diagnose, or speculate about modern equivalents. |

## 7. A path

- **One arc**, stated in the path `subtitle` and visible in the titles. A book path walks the book in order; a topic path moves from need to practice to rest.
- **Day 1** says what the path is; the **last day** ends gently: looks back, names a next step (for example "read Mark in the Bible tab"), and leaves the reader with a promise rather than a test.
- **Consistent pacing and tone** across the path; no lesson more than about 30% longer than the median.
- **Avoid repeating passages** another launch path already uses unless the repetition is deliberate.
- Metadata: `access` (`free` / `premium` / `seasonal`), `freePreviewLessons` for premium paths, `goals` and `levels` for onboarding, `sortOrder`. While a path is being written it carries `draft: {plannedLessons, note}`; remove `draft` only when every lesson is written and reviewed.

## 8. Review before merge

1. Validator and unit tests green (§1).
2. `python3 -I tools/content/content_summary.py --lessons` table in the PR body.
3. Spot-render at least three lessons per path in the app, light and dark.
4. An independent theology and accuracy review (someone who did not write the lessons): every study aid's history, every "first/only/always" claim, every quiz for a second defensible answer, tone on sensitive topics.
5. The author lists the weakest lessons honestly in the PR.
