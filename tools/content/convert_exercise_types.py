#!/usr/bin/env python3
"""Convert ~1 in 5 quiz questions per path to the non-choice exercise types.

    python3 -I tools/content/convert_exercise_types.py

Rewrites the listed questions in paths.json (idempotent: running it again changes nothing) and
then runs validate_content.py, which checks every blank, order token, match pair and quotation
against web.json. The literals below were copied from web.json; the validator is the proof.
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, "Shepherd", "Resources", "Content")
PATHS_FILE = os.path.join(CONTENT, "paths.json")
BIBLE_FILE = os.path.join(CONTENT, "web.json")

sys.path.insert(0, os.path.join(ROOT, "tools", "content"))
import validate_content as vc

def main():
    with open(PATHS_FILE, encoding="utf-8") as f:
        bundle = json.load(f)
    with open(BIBLE_FILE, encoding="utf-8") as f:
        bible = json.load(f)
    verses = vc.index(bible)

    # Let's inspect the text of verses for lessons we want to convert
    conversions = {}

    # =========================================================================
    # peace-14 (8 questions) - DO NOT touch peace-14.d01
    # =========================================================================

    # peace-14.d02.q1: MAT.6.26 (verses: MAT.6.25, MAT.6.26, MAT.6.27)
    # MAT.6.26: "See the birds of the sky, that they don’t sow, neither do they reap, nor gather into barns. Your heavenly Father feeds them. Aren’t you of much more value than they?"
    conversions["peace-14.d02.q1"] = {
        "type": "fill_blank",
        "prompt": "Fill in the blank: \"Your heavenly Father ___ them.\"",
        "choices": ["feeds", "creates", "guards", "leads"],
        "correctIndex": 0,
        "answerRef": "MAT.6.26",
        "explain": "Matthew 6:26: \"Your heavenly Father feeds them.\""
    }

    # peace-14.d03.q1: PSA.46.1 (verses: PSA.46.1, PSA.46.2, PSA.46.10)
    # PSA.46.1: "God is our refuge and strength, a very present help in trouble."
    conversions["peace-14.d03.q1"] = {
        "type": "fill_blank",
        "prompt": "Complete the verse: \"God is our refuge and ___, a very present help in trouble.\"",
        "choices": ["strength", "shield", "peace", "fortress"],
        "correctIndex": 0,
        "answerRef": "PSA.46.1",
        "explain": "Psalm 46:1: \"God is our refuge and strength, a very present help in trouble.\""
    }

    # peace-14.d05.q2: PSA.13.5 (verses: PSA.13.1, PSA.13.2, PSA.13.5, PSA.13.6)
    # PSA.13.5: "But I trust in your loving kindness. My heart rejoices in your salvation."
    conversions["peace-14.d05.q2"] = {
        "type": "order",
        "prompt": "Put the words of this verse in order:",
        "orderTokens": ["But I trust in", "your loving kindness.", "My heart rejoices", "in your salvation."],
        "answerRef": "PSA.13.5",
        "explain": "Psalm 13:5: \"But I trust in your loving kindness. My heart rejoices in your salvation.\""
    }

    # peace-14.d06.q2: PSA.42.5 (verses: PSA.42.1, PSA.42.2, PSA.42.5, PSA.42.11)
    # PSA.42.5: "Why are you in despair, my soul? Why are you disturbed within me? Hope in God! For I shall still praise him for the saving help of his presence."
    conversions["peace-14.d06.q2"] = {
        "type": "order",
        "prompt": "Put the words of this prayer in order:",
        "orderTokens": ["Why are you in despair,", "my soul?", "Why are you disturbed", "within me?"],
        "answerRef": "PSA.42.5",
        "explain": "Psalm 42:5: \"Why are you in despair, my soul? Why are you disturbed within me?\""
    }

    # peace-14.d08.q2: 1SA.1.15 (verses: 1SA.1.10, 1SA.1.13, 1SA.1.15, 1SA.1.18)
    # 1SA.1.15: "Hannah answered, “No, my lord, I am a woman who has a sorrowful spirit. I have been drinking neither wine nor strong drink, but I poured out my soul before the LORD."
    conversions["peace-14.d08.q2"] = {
        "type": "true_false",
        "prompt": "Hannah explained to Eli that she had poured out her soul before the LORD.",
        "choices": ["True", "False"],
        "correctIndex": 0,
        "answerRef": "1SA.1.15",
        "explain": "1 Samuel 1:15: Hannah says, \"I poured out my soul before the LORD.\""
    }

    # peace-14.d10.q2: PHP.4.6 (reworked after the PR #27 review)
    conversions["peace-14.d10.q2"] = {
        "type": "true_false",
        "prompt": "Paul says to make our requests known to God with thanksgiving.",
        "choices": [
            "True",
            "False"
        ],
        "correctIndex": 0,
        "answerRef": "PHP.4.6",
        "explain": "Philippians 4:6: \"by prayer and petition with thanksgiving, let your requests be made known to God.\""
    }

    # peace-14.d12.q2: PSA.4.1, PSA.4.8 (reworked after the PR #27 review)
    conversions["peace-14.d12.q2"] = {
        "type": "match",
        "prompt": "Match each reference to its verse:",
        "pairs": [
            {
                "ref": "PSA.4.1",
                "text": "Have mercy on me, and hear my prayer."
            },
            {
                "ref": "PSA.4.8",
                "text": "for you alone, LORD, make me live in safety"
            }
        ],
        "answerRef": "PSA.4.8",
        "explain": "Psalm 4:1 asks God for mercy, and Psalm 4:8 trusts him: \"for you alone, LORD, make me live in safety.\""
    }

    # peace-14.d14.q2: JHN.14.27 (reworked after the PR #27 review)
    conversions["peace-14.d14.q2"] = {
        "type": "true_false",
        "prompt": "Jesus says he gives his peace in the same way the world gives.",
        "choices": [
            "True",
            "False"
        ],
        "correctIndex": 1,
        "answerRef": "JHN.14.27",
        "explain": "John 14:27: \"My peace I give to you; not as the world gives, I give to you.\""
    }

    # =========================================================================
    # beginner-30 (17 questions) - DO NOT touch beginner-30.d30
    # =========================================================================

    # day2-q2: GEN.1.27 (verses: GEN.1.26, GEN.1.27)
    # GEN.1.27: "God created man in his own image. In God’s image he created him; male and female he created them."
    conversions["day2-q2"] = {
        "type": "order",
        "prompt": "Put the words of this verse in order:",
        "orderTokens": ["In God’s image", "he created him;", "male and female", "he created them."],
        "answerRef": "GEN.1.27",
        "explain": "Genesis 1:27: \"In God’s image he created him; male and female he created them.\""
    }

    # day3-q2: JHN.1.1 & JHN.1.14 (verses: JHN.1.1, JHN.1.14)
    # JHN.1.1: "In the beginning was the Word, and the Word was with God, and the Word was God."
    # JHN.1.14: "The Word became flesh and lived among us. We saw his glory, such glory as of the only born Son of the Father, full of grace and truth."
    conversions["day3-q2"] = {
        "type": "match",
        "prompt": "Match each reference to its statement about the Word:",
        "pairs": [
            {"ref": "JHN.1.1", "text": "In the beginning was the Word"},
            {"ref": "JHN.1.14", "text": "The Word became flesh and lived among us."}
        ],
        "answerRef": "JHN.1.14",
        "explain": "John 1:1 and John 1:14 declare that the Word was in the beginning and became flesh."
    }

    # day4-q2: JHN.3.17 (verses: JHN.3.16, JHN.3.17)
    # JHN.3.17: "For God didn’t send his Son into the world to judge the world, but that the world should be saved through him."
    conversions["day4-q2"] = {
        "type": "true_false",
        "prompt": "God sent his Son into the world to judge the world.",
        "choices": ["True", "False"],
        "correctIndex": 1,
        "answerRef": "JHN.3.17",
        "explain": "John 3:17: \"For God didn’t send his Son into the world to judge the world, but that the world should be saved through him.\""
    }

    # day5-q2: PSA.23.4 (reworked after the PR #27 review)
    conversions["day5-q2"] = {
        "type": "order",
        "prompt": "Put the words of Psalm 23:4 in order:",
        "orderTokens": [
            "Even though I walk through",
            "the valley of the shadow of death,",
            "I will fear no evil,",
            "for you are with me."
        ],
        "answerRef": "PSA.23.4",
        "explain": "Psalm 23:4: \"Even though I walk through the valley of the shadow of death, I will fear no evil, for you are with me.\""
    }

    # day7-q2: MAT.6.9 & PHP.4.6 (verses: MAT.6.9, MAT.6.11, PHP.4.6, PHP.4.7)
    # MAT.6.9: "Pray like this: “‘Our Father in heaven, may your name be kept holy."
    # PHP.4.6: "In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God."
    conversions["day7-q2"] = {
        "type": "match",
        "prompt": "Match each reference to its teaching on prayer:",
        "pairs": [
            {"ref": "MAT.6.9", "text": "Our Father in heaven, may your name be kept holy."},
            {"ref": "PHP.4.6", "text": "In nothing be anxious, but in everything"}
        ],
        "answerRef": "MAT.6.9",
        "explain": "Matthew 6:9 teaches addressing God in heaven, while Philippians 4:6 urges prayer in everything."
    }

    # beginner-30.d08.q1: JHN.10.11 (verses: JHN.10.11, JHN.10.14, JHN.10.27)
    # JHN.10.11: "I am the good shepherd. The good shepherd lays down his life for the sheep."
    conversions["beginner-30.d08.q1"] = {
        "type": "fill_blank",
        "prompt": "Fill in the blank: \"I am the good ___.\"",
        "choices": ["shepherd", "teacher", "physician", "servant"],
        "correctIndex": 0,
        "answerRef": "JHN.10.11",
        "explain": "John 10:11: \"I am the good shepherd. The good shepherd lays down his life for the sheep.\""
    }

    # beginner-30.d09.q2: LUK.15.5 (verses: LUK.15.4, LUK.15.5, LUK.15.6)
    # LUK.15.5: "When he has found it, he carries it on his shoulders, rejoicing."
    conversions["beginner-30.d09.q2"] = {
        "type": "true_false",
        "prompt": "When the shepherd finds the lost sheep, he carries it on his shoulders, rejoicing.",
        "choices": ["True", "False"],
        "correctIndex": 0,
        "answerRef": "LUK.15.5",
        "explain": "Luke 15:5: \"When he has found it, he carries it on his shoulders, rejoicing.\""
    }

    # beginner-30.d10.q2: LUK.15.22 (verses: LUK.15.20, LUK.15.22, LUK.15.24)
    # LUK.15.22: "“But the father said to his servants, ‘Bring out the best robe, and put it on him. Put a ring on his hand, and sandals on his feet."
    conversions["beginner-30.d10.q2"] = {
        "type": "fill_blank",
        "prompt": "Fill in the blank: \"Bring out the best ___ and put it on him.\"",
        "choices": ["robe", "ring", "crown", "sandals"],
        "correctIndex": 0,
        "answerRef": "LUK.15.22",
        "explain": "Luke 15:22: The father tells his servants to bring out the best robe and put it on him."
    }

    # beginner-30.d12.q2: ROM.5.7, ROM.5.8 (reworked after the PR #27 review)
    conversions["beginner-30.d12.q2"] = {
        "type": "match",
        "prompt": "Match each reference to its verse:",
        "pairs": [
            {
                "ref": "ROM.5.7",
                "text": "For one will hardly die for a righteous man."
            },
            {
                "ref": "ROM.5.8",
                "text": "while we were yet sinners, Christ died for us."
            }
        ],
        "answerRef": "ROM.5.8",
        "explain": "Romans 5:7 and Romans 5:8: someone will hardly die even for a righteous man, but \"while we were yet sinners, Christ died for us.\""
    }

    # beginner-30.d14.q2: JHN.1.45 (verses: JHN.1.43, JHN.1.45, JHN.1.46)
    # JHN.1.45: "Philip found Nathanael, and said to him, “We have found him, of whom Moses in the law, and also the prophets, wrote: Jesus of Nazareth, the son of Joseph.”"
    conversions["beginner-30.d14.q2"] = {
        "type": "true_false",
        "prompt": "Philip told Nathanael that they had found the one of whom Moses in the law wrote.",
        "choices": ["True", "False"],
        "correctIndex": 0,
        "answerRef": "JHN.1.45",
        "explain": "John 1:45: Philip says they found him of whom Moses and the prophets wrote."
    }

    # beginner-30.d15.q1: JHN.14.6 (verses: JHN.14.1, JHN.14.6)
    # JHN.14.6: "Jesus said to him, “I am the way, the truth, and the life. No one comes to the Father, except through me."
    conversions["beginner-30.d15.q1"] = {
        "type": "fill_blank",
        "prompt": "Complete Jesus’ words: \"I am the way, the truth, and the ___.\"",
        "choices": ["life", "light", "door", "resurrection"],
        "correctIndex": 0,
        "answerRef": "JHN.14.6",
        "explain": "John 14:6: Jesus said, \"I am the way, the truth, and the life.\""
    }

    # beginner-30.d16.q2: JHN.15.5 (verses: JHN.15.1, JHN.15.4, JHN.15.5)
    # JHN.15.5: "I am the vine. You are the branches. He who remains in me and I in him bears much fruit, for apart from me you can do nothing."
    conversions["beginner-30.d16.q2"] = {
        "type": "order",
        "prompt": "Put Jesus’ words in order:",
        "orderTokens": ["I am the vine.", "You are the branches.", "He who remains in me", "and I in him", "bears much fruit,"],
        "answerRef": "JHN.15.5",
        "explain": "John 15:5: \"I am the vine. You are the branches. He who remains in me and I in him bears much fruit,\""
    }

    # beginner-30.d17.q1: PSA.119.105 (verses: PSA.119.105, PSA.119.130)
    # PSA.119.105: "Your word is a lamp to my feet, and a light for my path."
    conversions["beginner-30.d17.q1"] = {
        "type": "fill_blank",
        "prompt": "Complete the verse: \"Your word is a lamp to my ___, and a light for my path.\"",
        "choices": ["feet", "eyes", "steps", "heart"],
        "correctIndex": 0,
        "answerRef": "PSA.119.105",
        "explain": "Psalm 119:105: \"Your word is a lamp to my feet, and a light for my path.\""
    }

    # beginner-30.d20.q2: MAT.22.39 (verses: MAT.22.36, MAT.22.37, MAT.22.39, MAT.22.40)
    # MAT.22.39: "A second likewise is this, ‘You shall love your neighbor as yourself.’"
    conversions["beginner-30.d20.q2"] = {
        "type": "true_false",
        "prompt": "Jesus said the second greatest commandment is to love your neighbor as yourself.",
        "choices": ["True", "False"],
        "correctIndex": 0,
        "answerRef": "MAT.22.39",
        "explain": "Matthew 22:39: \"A second likewise is this, ‘You shall love your neighbor as yourself.’\""
    }

    # beginner-30.d21.q1: 1CO.13.4 (verses: 1CO.13.4, 1CO.13.7, 1CO.13.13)
    # 1CO.13.4: "Love is patient and is kind. Love doesn’t envy. Love doesn’t brag, is not proud,"
    conversions["beginner-30.d21.q1"] = {
        "type": "fill_blank",
        "prompt": "Complete the verse: \"Love is ___ and is kind.\"",
        "choices": ["patient", "hopeful", "humble", "merciful"],
        "correctIndex": 0,
        "answerRef": "1CO.13.4",
        "explain": "1 Corinthians 13:4: \"Love is patient and is kind. Love doesn’t envy. Love doesn’t brag, is not proud,\""
    }

    # beginner-30.d23.q2: MAT.18.21 (reworked after the PR #27 review)
    conversions["beginner-30.d23.q2"] = {
        "type": "order",
        "prompt": "Put Peter's question to Jesus in order:",
        "orderTokens": [
            "Lord, how often",
            "shall my brother sin against me,",
            "and I forgive him?",
            "Until seven times?"
        ],
        "answerRef": "MAT.18.21",
        "explain": "Matthew 18:21: Peter asked, \"Lord, how often shall my brother sin against me, and I forgive him? Until seven times?\""
    }

    # beginner-30.d28.q2: LUK.24.3, LUK.24.5 (reworked after the PR #27 review)
    conversions["beginner-30.d28.q2"] = {
        "type": "match",
        "prompt": "Match each reference to what happened at the tomb:",
        "pairs": [
            {
                "ref": "LUK.24.3",
                "text": "They entered in, and didn’t find the Lord Jesus’ body."
            },
            {
                "ref": "LUK.24.5",
                "text": "Why do you seek the living among the dead?"
            }
        ],
        "answerRef": "LUK.24.5",
        "explain": "Luke 24:3 and Luke 24:5: the women did not find the body, and the two men asked, \"Why do you seek the living among the dead?\""
    }

    # =========================================================================
    # mark-30 (18 questions)
    # =========================================================================

    # mark-30.d01.q2: MRK.1.14 (verses: MRK.1.1, MRK.1.14, MRK.1.15)
    # MRK.1.14: "Now after John was taken into custody, Jesus came into Galilee, preaching the Good News of God’s Kingdom,"
    conversions["mark-30.d01.q2"] = {
        "type": "order",
        "prompt": "Put the words of this verse in order:",
        "orderTokens": ["Jesus came into Galilee,", "preaching the Good News", "of God’s Kingdom,"],
        "answerRef": "MRK.1.14",
        "explain": "Mark 1:14: \"Jesus came into Galilee, preaching the Good News of God’s Kingdom,\""
    }

    # mark-30.d02.q2: MRK.1.16 & MRK.1.17 (verses: MRK.1.16, MRK.1.17, MRK.1.18)
    # MRK.1.16: "Passing along by the sea of Galilee, he saw Simon and Andrew, the brother of Simon, casting a net into the sea, for they were fishermen."
    # MRK.1.17: "Jesus said to them, “Come after me, and I will make you into fishers for men.”"
    conversions["mark-30.d02.q2"] = {
        "type": "match",
        "prompt": "Match each reference to what happened by the Sea of Galilee:",
        "pairs": [
            {"ref": "MRK.1.16", "text": "casting a net into the sea, for they were fishermen."},
            {"ref": "MRK.1.17", "text": "Come after me, and I will make you into fishers for men."}
        ],
        "answerRef": "MRK.1.16",
        "explain": "Mark 1:16 and Mark 1:17 record Jesus seeing fishermen casting a net and calling them to become fishers for men."
    }

    # mark-30.d03.q2: MRK.1.35 (verses: MRK.1.35, MRK.1.36, MRK.1.37, MRK.1.38)
    # MRK.1.35: "Early in the morning, while it was still dark, he rose up and went out, and departed into a deserted place, and prayed there."
    conversions["mark-30.d03.q2"] = {
        "type": "true_false",
        "prompt": "Early in the morning, while it was still dark, Jesus went out to a deserted place to pray.",
        "choices": ["True", "False"],
        "correctIndex": 0,
        "answerRef": "MRK.1.35",
        "explain": "Mark 1:35: \"Early in the morning, while it was still dark, he rose up and went out, and departed into a deserted place, and prayed there.\""
    }

    # mark-30.d04.q2: MRK.1.41 (verses: MRK.1.40, MRK.1.41, MRK.1.42)
    # MRK.1.41: "Being moved with compassion, he stretched out his hand, and touched him, and said to him, “I want to. Be made clean.”"
    conversions["mark-30.d04.q2"] = {
        "type": "order",
        "prompt": "Put Jesus’ action and words in order:",
        "orderTokens": ["he stretched out his hand,", "and touched him,", "and said to him,", "“I want to.", "Be made clean.”"],
        "answerRef": "MRK.1.41",
        "explain": "Mark 1:41: \"he stretched out his hand, and touched him, and said to him, “I want to. Be made clean.”\""
    }

    # mark-30.d05.q2: MRK.2.5 (verses: MRK.2.3, MRK.2.4, MRK.2.5, MRK.2.12)
    # MRK.2.5: "Jesus, seeing their faith, said to the paralytic, “Son, your sins are forgiven you.”"
    conversions["mark-30.d05.q2"] = {
        "type": "true_false",
        "prompt": "Jesus saw their faith before speaking to the paralyzed man.",
        "choices": ["True", "False"],
        "correctIndex": 0,
        "answerRef": "MRK.2.5",
        "explain": "Mark 2:5: \"Jesus, seeing their faith, said to the paralytic, “Son, your sins are forgiven you.”\""
    }

    # mark-30.d06.q3: MRK.2.17 (verses: MRK.2.14, MRK.2.15, MRK.2.16, MRK.2.17)
    # MRK.2.17: "When Jesus heard it, he said to them, “Those who are healthy have no need for a physician, but those who are sick. I came not to call the righteous, but sinners to repentance.”"
    conversions["mark-30.d06.q3"] = {
        "type": "fill_blank",
        "prompt": "Complete Jesus’ words: \"Those who are healthy have no need for a ___, but those who are sick.\"",
        "choices": ["physician", "teacher", "ruler", "priest"],
        "correctIndex": 0,
        "answerRef": "MRK.2.17",
        "explain": "Mark 2:17: \"Those who are healthy have no need for a physician, but those who are sick.\""
    }

    # mark-30.d08.q1: MRK.4.14 (verses: MRK.4.3, MRK.4.14, MRK.4.20)
    # MRK.4.14: "The farmer sows the word."
    conversions["mark-30.d08.q1"] = {
        "type": "fill_blank",
        "prompt": "Complete the verse: \"The farmer sows the ___.\"",
        "choices": ["word", "wheat", "mustard seed", "barley"],
        "correctIndex": 0,
        "answerRef": "MRK.4.14",
        "explain": "Mark 4:14: \"The farmer sows the word.\""
    }

    # mark-30.d09.q2: MRK.4.39 (verses: MRK.4.37, MRK.4.38, MRK.4.39)
    # MRK.4.39: "He awoke, and rebuked the wind, and said to the sea, “Peace! Be still!” The wind ceased, and there was a great calm."
    conversions["mark-30.d09.q2"] = {
        "type": "fill_blank",
        "prompt": "Complete Jesus’ words to the sea: \"Peace! Be ___!\"",
        "choices": ["still", "calm", "quiet", "obedient"],
        "correctIndex": 0,
        "answerRef": "MRK.4.39",
        "explain": "Mark 4:39: He rebuked the wind, and said to the sea, \"Peace! Be still!\""
    }

    # mark-30.d10.q2: MRK.5.19 & MRK.5.20 (verses: MRK.5.15, MRK.5.18, MRK.5.19, MRK.5.20)
    # MRK.5.19: "He didn’t allow him, but said to him, “Go to your house, to your friends, and tell them what great things the Lord has done for you, and how he had mercy on you.”"
    # MRK.5.20: "He went his way, and began to proclaim in Decapolis how Jesus had done great things for him, and everyone marveled."
    conversions["mark-30.d10.q2"] = {
        "type": "match",
        "prompt": "Match each reference to its verse:",
        "pairs": [
            {"ref": "MRK.5.19", "text": "tell them what great things the Lord has done for you"},
            {"ref": "MRK.5.20", "text": "began to proclaim in Decapolis how Jesus had done great things for him"}
        ],
        "answerRef": "MRK.5.19",
        "explain": "Mark 5:19 and Mark 5:20 describe Jesus telling the healed man to share what the Lord had done, and his proclamation in Decapolis."
    }

    # mark-30.d11.q2: MRK.5.36 (reworked after the PR #27 review)
    conversions["mark-30.d11.q2"] = {
        "type": "order",
        "prompt": "Put Jesus’ reassuring words to Jairus in order:",
        "orderTokens": [
            "Don’t",
            "be afraid,",
            "only believe."
        ],
        "answerRef": "MRK.5.36",
        "explain": "Mark 5:36: Jesus said to the ruler of the synagogue, \"Don’t be afraid, only believe.\""
    }

    # mark-30.d13.q2: MRK.6.49 (reworked after the PR #27 review)
    conversions["mark-30.d13.q2"] = {
        "type": "true_false",
        "prompt": "When the disciples saw Jesus walking on the sea, they thought he was an angel.",
        "choices": [
            "True",
            "False"
        ],
        "correctIndex": 1,
        "answerRef": "MRK.6.49",
        "explain": "Mark 6:49: they \"supposed that it was a ghost, and cried out.\""
    }

    # mark-30.d15.q2: MRK.8.29 (reworked after the PR #27 review)
    conversions["mark-30.d15.q2"] = {
        "type": "order",
        "prompt": "Put Peter’s answer in order:",
        "orderTokens": [
            "Peter answered,",
            "“You are",
            "the Christ.”"
        ],
        "answerRef": "MRK.8.29",
        "explain": "Mark 8:29: Peter answered, \"You are the Christ.\""
    }

    # mark-30.d16.q2: MRK.8.34 (verses: MRK.8.34, MRK.8.35, MRK.8.36)
    # MRK.8.34: "He called the multitude to himself with his disciples, and said to them, “Whoever wants to come after me, let him deny himself, and take up his cross, and follow me."
    conversions["mark-30.d16.q2"] = {
        "type": "fill_blank",
        "prompt": "Complete the verse: \"let him deny himself, and take up his ___, and follow me.\"",
        "choices": ["cross", "yoke", "staff", "sword"],
        "correctIndex": 0,
        "answerRef": "MRK.8.34",
        "explain": "Mark 8:34: \"Whoever wants to come after me, let him deny himself, and take up his cross, and follow me.\""
    }

    # mark-30.d18.q2: MRK.9.24 (verses: MRK.9.17, MRK.9.23, MRK.9.24)
    # MRK.9.24: "Immediately the father of the child cried out with tears, “I believe. Help my unbelief!”"
    conversions["mark-30.d18.q2"] = {
        "type": "true_false",
        "prompt": "The father of the child cried out: 'I believe. Help my unbelief!'",
        "choices": ["True", "False"],
        "correctIndex": 0,
        "answerRef": "MRK.9.24",
        "explain": "Mark 9:24: \"Immediately the father of the child cried out with tears, “I believe. Help my unbelief!”\""
    }

    # mark-30.d21.q2: MRK.10.43 & MRK.10.45 (verses: MRK.10.42, MRK.10.43, MRK.10.45)
    # MRK.10.43: "But it shall not be so among you, but whoever wants to become great among you shall be your servant."
    # MRK.10.45: "For the Son of Man also came not to be served but to serve, and to give his life as a ransom for many.”"
    conversions["mark-30.d21.q2"] = {
        "type": "match",
        "prompt": "Match each reference to Jesus’ teaching:",
        "pairs": [
            {"ref": "MRK.10.43", "text": "whoever wants to become great among you shall be your servant."},
            {"ref": "MRK.10.45", "text": "For the Son of Man also came not to be served but to serve"}
        ],
        "answerRef": "MRK.10.45",
        "explain": "Mark 10:43 and Mark 10:45 teach that greatness comes through serving, following the Son of Man who came to serve."
    }

    # mark-30.d23.q3: MRK.11.9 (verses: MRK.11.7, MRK.11.8, MRK.11.9)
    # MRK.11.9: "Those who went in front, and those who followed, cried out, “Hosanna! Blessed is he who comes in the name of the Lord!"
    conversions["mark-30.d23.q3"] = {
        "type": "fill_blank",
        "prompt": "Complete the crowd’s cry: \"Hosanna! Blessed is he who comes in the name of the ___!\"",
        "choices": ["Lord", "King", "Prophet", "Father"],
        "correctIndex": 0,
        "answerRef": "MRK.11.9",
        "explain": "Mark 11:9: \"Hosanna! Blessed is he who comes in the name of the Lord!\""
    }

    # mark-30.d26.q2: MRK.14.23, MRK.14.24 (reworked after the PR #27 review)
    conversions["mark-30.d26.q2"] = {
        "type": "match",
        "prompt": "Match each reference to its verse:",
        "pairs": [
            {
                "ref": "MRK.14.23",
                "text": "He took the cup, and when he had given thanks"
            },
            {
                "ref": "MRK.14.24",
                "text": "This is my blood of the new covenant"
            }
        ],
        "answerRef": "MRK.14.24",
        "explain": "Mark 14:23 and Mark 14:24: Jesus gave thanks for the cup and said, \"This is my blood of the new covenant.\""
    }

    # mark-30.d27.q2: MRK.14.36 (reworked after the PR #27 review)
    conversions["mark-30.d27.q2"] = {
        "type": "order",
        "prompt": "Put Jesus’ prayer in Gethsemane in order:",
        "orderTokens": [
            "However,",
            "not what I desire,",
            "but what you desire."
        ],
        "answerRef": "MRK.14.36",
        "explain": "Mark 14:36: \"However, not what I desire, but what you desire.\""
    }

    # Apply conversions
    converted_count = 0
    for path in bundle["paths"]:
        pid = path["id"]
        for lesson in path["lessons"]:
            for q in lesson["quiz"]:
                qid = q["id"]
                if qid in conversions:
                    update = conversions[qid]
                    # Drop fields of the question's previous type that this one does not use,
                    # then apply it (existing keys keep their position, so reruns are no-ops).
                    for k in ("choices", "correctIndex", "orderTokens", "pairs"):
                        if k not in update:
                            q.pop(k, None)
                    for k, v in update.items():
                        q[k] = v
                    converted_count += 1

    print(f"Applying {converted_count} conversions...")
    with open(PATHS_FILE, "w", encoding="utf-8") as f:
        json.dump(bundle, f, indent=2, ensure_ascii=False)
        f.write("\n")

    # Run validation immediately
    errs, warns = vc.validate(bible, bundle, release=True)
    for e in errs:
        print("ERROR:", e)
    for w in warns:
        print("WARN :", w)
    print(f"Result: {len(errs)} errors, {len(warns)} warnings.")

    if errs:
        sys.exit(1)
    else:
        print("ALL CONVERSIONS PASSED VALIDATION PERFECTLY!")

if __name__ == "__main__":
    main()
