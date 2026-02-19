const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const OpenAI = require("openai");
const fetch = require("node-fetch");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

/* =========================================================
   CoinGecko Fetch
========================================================= */

async function fetchTopCoins() {
    const url =
        "https://api.coingecko.com/api/v3/coins/markets" +
        "?vs_currency=eur" +
        "&order=market_cap_desc" +
        "&per_page=20" +
        "&page=1" +
        "&price_change_percentage=24h";

    const res = await fetch(url);

    if (!res.ok) {
        throw new Error(`CoinGecko API failed: ${res.status}`);
    }

    const data = await res.json();

    if (!Array.isArray(data) || data.length !== 20) {
        throw new Error("CoinGecko did not return 20 coins");
    }

    return data.map((coin) => ({
        id: coin.id,
        name: coin.name,
        symbol: coin.symbol,
        change24h: coin.price_change_percentage_24h || 0,
        athChangePercent: coin.ath_change_percentage || 0,
        marketRank: coin.market_cap_rank || 0,
    }));
}

/* =========================================================
   Deterministic Vibe Score
========================================================= */

function calculateVibe(coin) {
    if (!coin) return 50;

    let score = 50;

    if (coin.change24h > 8) score += 15;
    if (coin.change24h < -8) score -= 15;
    if (coin.athChangePercent < -70) score -= 10;
    if (coin.marketRank <= 10) score += 10;

    return Math.max(0, Math.min(100, score));
}

/* =========================================================
   BAE BIBLE
========================================================= */

const BAE_BIBLE_PROMPT = `
You are Crypto Bae.

Universal Rules:
- Toxic, ironic, spicy ex vibe.
- Use Gen Z slang: delulu, aura, rizz, red flag, situationship.
- Never corporate.
- Never educational.

VIP Archetypes:
Bitcoin → Toxic Rich Ex.
Ethereum → Hipster Upgrade Guy.
Solana → Party Animal that collapses.
Dogecoin → Golden Retriever Ex.
Cardano → Eternal Student.

Category Archetypes:
Memecoins → brain rot buyers.
AI Coins → fake Elon Musk energy.
Stablecoins → scared boring energy.
Gaming Coins → go touch grass.

Dynamic Rules:
If 24h change < -10% → red flag energy.
If 24h change > 10% → lucky delulu pump.
If ATH distance < -70% → trauma energy.
If marketRank > 200 → irrelevant energy.
`;

/* =========================================================
   Locale Layer
========================================================= */

function getLocalePrompt(lang) {
    if (lang === "el") {
        return `
Write in modern Greek.
Use Greek Gen Z slang.
Keep crypto slang words like delulu, rug pull, aura in English.
Sarcastic, spicy tone.
`;
    }

    return `
Write in English Gen Z tone.
Chaotic, meme-ready, savage.
`;
}

/* =========================================================
   AI Generation (STABLE VERSION)
========================================================= */

async function generateRoastsForLanguage(coins, lang, openai) {
    const structuredInput = coins
        .map(
            (c) =>
                `id: ${c.id}, name: ${c.name}, symbol: ${c.symbol}, change24h: ${c.change24h}, athDistance: ${c.athChangePercent}, rank: ${c.marketRank}`
        )
        .join("\n");

    const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        temperature: 0.9,
        max_tokens: 1500,
        response_format: { type: "json_object" },
        messages: [
            {
                role: "system",
                content: `
${BAE_BIBLE_PROMPT}
${getLocalePrompt(lang)}

Each roast MUST include at least one emoji from:
💅 🚩 🤡 💀 🙄

You MUST return EXACTLY 20 items.
If not 20, the output is invalid.
Return STRICT JSON only.
No markdown.
No extra text.
        `,
            },
            {
                role: "user",
                content: `
Generate 20 roasts for the following coins:

${structuredInput}

Return exactly this structure:

{
  "coins": [
    { "id": "bitcoin", "roast": "..." }
  ]
}
        `,
            },
        ],
    });

    const parsed = JSON.parse(completion.choices[0].message.content);

    if (!parsed.coins || !Array.isArray(parsed.coins)) {
        throw new Error("AI response malformed");
    }

    if (parsed.coins.length !== 20) {
        throw new Error("AI did not return exactly 20 coins");
    }

    return parsed.coins;
}

/* =========================================================
   Scheduled Generator
========================================================= */

exports.generateDailyRoasts = onSchedule(
    {
        schedule: "every day 08:00",
        region: "europe-west1",
        secrets: [OPENAI_API_KEY],
        memory: "1GiB",
        timeoutSeconds: 120,
    },
    async () => {
        try {
            const openai = new OpenAI({
                apiKey: OPENAI_API_KEY.value(),
            });

            const coins = await fetchTopCoins();
            const languages = ["en", "el"];
            const today = new Date().toISOString().split("T")[0];

            const result = { date: today, languages: {} };

            for (const lang of languages) {
                const roasts = await generateRoastsForLanguage(
                    coins,
                    lang,
                    openai
                );

                const enriched = roasts.map((r) => {
                    const originalCoin = coins.find((c) => c.id === r.id);
                    return {
                        id: r.id,
                        roast: r.roast,
                        vibe_score: calculateVibe(originalCoin),
                    };
                });

                result.languages[lang] = { coins: enriched };
            }

            await db.collection("daily_roasts").doc(today).set(result);

            console.log("Daily roasts generated successfully");
        } catch (err) {
            console.error("Scheduled generation failed:", err);
        }
    }
);

/* =========================================================
   Manual Trigger
========================================================= */

exports.generateDailyRoastsNow = onCall(
    {
        region: "europe-west1",
        secrets: [OPENAI_API_KEY],
        memory: "1GiB",
        timeoutSeconds: 120,
    },
    async () => {
        try {
            const openai = new OpenAI({
                apiKey: OPENAI_API_KEY.value(),
            });

            const coins = await fetchTopCoins();
            const languages = ["en", "el"];
            const today = new Date().toISOString().split("T")[0];

            const result = { date: today, languages: {} };

            for (const lang of languages) {
                const roasts = await generateRoastsForLanguage(
                    coins,
                    lang,
                    openai
                );

                const enriched = roasts.map((r) => {
                    const originalCoin = coins.find((c) => c.id === r.id);
                    return {
                        id: r.id,
                        roast: r.roast,
                        vibe_score: calculateVibe(originalCoin),
                    };
                });

                result.languages[lang] = { coins: enriched };
            }

            await db.collection("daily_roasts").doc(today).set(result);

            return { success: true };
        } catch (err) {
            console.error("Manual generation failed:", err);
            throw new Error("Generation failed");
        }
    }
);