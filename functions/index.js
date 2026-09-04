const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const getUtcDateString = (date = new Date()) => {
  const yyyy = date.getUTCFullYear();
  const mm = String(date.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(date.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
};

const DOMAIN_TEMPLATES = [
  {
    category: "Gaming & Play",
    subthemes: [
      "Emergent gameplay and unscripted player creativity",
      "The psychology of easter eggs and secret rooms in game worlds",
      "Speedrunning and how players deconstruct game systems",
      "Finite vs infinite games: Playing to win vs playing to keep playing",
      "Procedural generation and computational art in games",
      "The Ludic Loop: Why simple loops captivate human attention"
    ]
  },
  {
    category: "Arts & Craft",
    subthemes: [
      "Kintsugi and finding value in golden repairs (Wabi-Sabi)",
      "Brutalism vs Art Deco: How architectural spaces shape human emotion",
      "Color theory and why certain hues evoke psychological reactions",
      "The mathematics of origami and space satellite solar panels",
      "Typography as the invisible architecture of language",
      "Lo-Fi aesthetics, grain, and digital nostalgia"
    ]
  },
  {
    category: "Social Dynamics",
    subthemes: [
      "Dunbar's number and the cognitive limit of genuine friendships",
      "Third Places: Why coffee shops and community spaces keep cities sane",
      "Social contagion and how behaviors spread like wildfire",
      "The psychology of internet memes and modern digital folklore",
      "Parasocial bonds in the era of streaming and podcasts",
      "The bystander effect and breaking the diffusion of responsibility"
    ]
  },
  {
    category: "Science & Nature",
    subthemes: [
      "Biomimicry: Brilliant technologies copied directly from animals and plants",
      "Mycelial networks: The underground communication web of forests",
      "Quantum entanglement and non-locality explained without jargon",
      "Deep ocean bioluminescence and alien ecosystems on Earth",
      "The Fermi Paradox: The eerie silence of the cosmos",
      "Circadian rhythms and how modern light altered human biology"
    ]
  },
  {
    category: "Cognitive Science",
    subthemes: [
      "The Paradox of Choice: Why having 100 options paralyzes us",
      "The Illusory Truth Effect: How repetition tricks our brain into belief",
      "Flow state neurochemistry and the conditions for effortless focus",
      "Synesthesia: How the brain sometimes crosses sensory wires",
      "Inversion thinking: Solving problems by focusing on what to avoid"
    ]
  },
  {
    category: "Music & Sound",
    subthemes: [
      "The neurology of earworms: Why songs get trapped on a cognitive loop",
      "Acoustic resonance, binaural perception, and spatial sound",
      "How Brian Eno invented ambient music while recovering in a hospital bed",
      "Microtonal scales and cultural emotions unfamiliar to western tuning"
    ]
  },
  {
    category: "Everyday Oddities",
    subthemes: [
      "Accidental inventions: How kitchen and laboratory mistakes changed the world",
      "Why the QWERTY keyboard layout was built to prevent mechanical jamming",
      "The sociology of quirky hobbies and obsessive micro-communities",
      "Lost cultural traditions that were surprisingly practical"
    ]
  },
  {
    category: "Philosophy & Mind",
    subthemes: [
      "The Ship of Theseus: How you remain yourself while every cell changes",
      "The Dichotomy of Control: Finding clarity in a noisy information stream",
      "The Map is Not the Territory: Alfred Korzybski's cognitive trap",
      "Absurdism and the liberating freedom of creating your own meaning"
    ]
  }
];

const generateSingleLesson = async (dateStr, domain, docId, recentHooks = []) => {
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) {
    throw new Error("OPENROUTER_API_KEY is not configured in environment.");
  }

  const randomSubtheme = domain.subthemes[Math.floor(Math.random() * domain.subthemes.length)];
  const avoidClause = recentHooks.length > 0
    ? `Avoid repeating or echoing these recently covered concepts: ${recentHooks.slice(0, 8).join("; ")}.`
    : "";

  const response = await axios.post(
    "https://openrouter.ai/api/v1/chat/completions",
    {
      model: "meta-llama/llama-3.3-70b-instruct",
      temperature: 0.9,
      top_p: 0.95,
      messages: [
        {
          role: "system",
          content: "You are a master cross-disciplinary educator and storyteller for Outside, a micro-learning mobile app designed to broaden horizons and break cognitive echo chambers. The topics should be vibrant, fascinating, and diverse: gaming, arts and craft, social dynamics, music, everyday oddities, science, and mental models. Do not make every lesson purely dry academic philosophy. Keep the voice witty, curious, intellectually refreshing, and accessible. Format your response strictly as valid JSON without markdown wrapping or code blocks. JSON structure: {\"category\": \"Category Name\", \"hook\": \"A punchy, curious 1-2 sentence hook.\", \"idea\": \"2 to 3 engaging paragraphs explaining the concept clearly with vivid examples.\", \"whyItMatters\": \"1 to 2 paragraphs explaining how this shifts everyday perspective.\", \"everydayExample\": \"A relatable, modern real-world scenario.\", \"reflectionPrompt\": \"A thought-provoking journaling or conversation prompt.\", \"exploreMore\": [\"https://en.wikipedia.org/...\", \"https://...\"], \"readTimeMinutes\": 3}"
        },
        {
          role: "user",
          content: `Create an eye-opening lesson for category "${domain.category}" exploring the theme "${randomSubtheme}". Date: ${dateStr}. ${avoidClause} Ensure links point to real academic, historical, or cultural reference sources.`
        }
      ]
    },
    {
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "HTTP-Referer": "https://outside.app",
        "X-Title": "Outside Micro-Learning",
        "Content-Type": "application/json"
      },
      timeout: 60000
    }
  );

  const rawContent = response.data?.choices?.[0]?.message?.content;
  if (!rawContent) {
    throw new Error("No content received from OpenRouter completion.");
  }

  let cleanContent = rawContent.trim();
  if (cleanContent.startsWith("```")) {
    cleanContent = cleanContent.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();
  }

  const lessonData = JSON.parse(cleanContent);
  const db = admin.firestore();

  const lessonPayload = {
    id: docId,
    publishDate: dateStr,
    category: lessonData.category || domain.category,
    hook: lessonData.hook || "",
    idea: lessonData.idea || "",
    whyItMatters: lessonData.whyItMatters || "",
    everydayExample: lessonData.everydayExample || "",
    reflectionPrompt: lessonData.reflectionPrompt || "",
    exploreMore: Array.isArray(lessonData.exploreMore) ? lessonData.exploreMore : [],
    readTimeMinutes: Number(lessonData.readTimeMinutes) || 3,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection("lessons").doc(docId).set(lessonPayload);
  return lessonPayload;
};

const generateDailyPool = async (targetDateStr) => {
  const dateStr = targetDateStr || getUtcDateString();
  const db = admin.firestore();

  const recentSnap = await db.collection("lessons")
    .orderBy("createdAt", "desc")
    .limit(12)
    .get();

  const recentHooks = [];
  recentSnap.forEach((doc) => {
    const data = doc.data();
    if (data.hook) recentHooks.push(data.hook);
  });

  const shuffledDomains = [...DOMAIN_TEMPLATES].sort(() => 0.5 - Math.random());
  const selectedDomains = shuffledDomains.slice(0, 3);

  const docIds = [dateStr, `${dateStr}_2`, `${dateStr}_3`];
  const promises = selectedDomains.map((domain, index) =>
    generateSingleLesson(dateStr, domain, docIds[index], recentHooks)
  );

  const results = await Promise.allSettled(promises);
  const successfulLessons = [];

  for (let i = 0; i < results.length; i++) {
    if (results[i].status === "fulfilled") {
      successfulLessons.push(results[i].value);
    } else {
      console.error(`Failed to generate perspective ${i + 1}:`, results[i].reason?.message || results[i].reason);
    }
  }

  if (successfulLessons.length === 0) {
    throw new Error("Failed to generate any perspectives in daily pool.");
  }

  return successfulLessons;
};

exports.generateDailyLesson = onSchedule("0 0 * * *", async () => {
  try {
    const pool = await generateDailyPool();
    console.log(`Successfully generated daily pool of ${pool.length} lessons.`);
  } catch (error) {
    console.error("Error in generateDailyLesson:", error.response?.data || error.message);
    throw error;
  }
});

exports.manualGenerateDailyLesson = onRequest({ cors: true }, async (req, res) => {
  try {
    const targetDate = req.query.date || req.body?.date;
    const pool = await generateDailyPool(targetDate);
    res.status(200).json({ success: true, count: pool.length, lessons: pool });
  } catch (error) {
    console.error("Error in manualGenerateDailyLesson:", error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || null
    });
  }
});

exports.broadcastMorningLesson = onSchedule("0 8 * * *", async () => {
  try {
    const todayStr = getUtcDateString();
    const db = admin.firestore();

    const snap = await db.collection("lessons")
      .where("publishDate", "==", todayStr)
      .limit(5)
      .get();

    if (snap.empty) {
      throw new Error(`No lessons found for ${todayStr}`);
    }

    const availableDocs = snap.docs.map((d) => d.data());
    const randomLesson = availableDocs[Math.floor(Math.random() * availableDocs.length)];

    const restApiKey = process.env.ONESIGNAL_REST_API_KEY;

    await axios.post(
      "https://onesignal.com/api/v1/notifications",
      {
        app_id: "b1ad390f-d626-4ca3-939a-6b5e144c1dcb",
        included_segments: ["Subscribed Users"],
        headings: { en: `Today in Outside • ${randomLesson.category}` },
        contents: { en: randomLesson.hook || "Step outside your echo chamber today." },
        data: { lessonId: randomLesson.id || todayStr }
      },
      {
        headers: {
          "Authorization": `Key ${restApiKey}`,
          "Content-Type": "application/json"
        }
      }
    );
  } catch (error) {
    console.error("Error in broadcastMorningLesson:", error.response?.data || error.message);
    throw error;
  }
});

exports.sendEveningReminders = onSchedule("0 20 * * *", async () => {
  try {
    const startOfToday = new Date();
    startOfToday.setUTCHours(0, 0, 0, 0);

    const db = admin.firestore();
    const usersSnapshot = await db.collection("users").get();
    const uids = [];

    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      const lastCompleted = data.lastCompletedDate;
      if (!lastCompleted) {
        uids.push(doc.id);
      } else {
        const lastCompletedDate = lastCompleted.toDate();
        if (lastCompletedDate < startOfToday) {
          uids.push(doc.id);
        }
      }
    });

    if (uids.length === 0) {
      return;
    }

    const restApiKey = process.env.ONESIGNAL_REST_API_KEY;
    const CHUNK_SIZE = 2000;

    for (let i = 0; i < uids.length; i += CHUNK_SIZE) {
      const chunk = uids.slice(i, i + CHUNK_SIZE);
      await axios.post(
        "https://onesignal.com/api/v1/notifications",
        {
          app_id: "b1ad390f-d626-4ca3-939a-6b5e144c1dcb",
          include_aliases: { external_id: chunk },
          include_external_user_ids: chunk,
          contents: { en: "Your streak is at risk. Step outside your bubble before tomorrow." }
        },
        {
          headers: {
            "Authorization": `Key ${restApiKey}`,
            "Content-Type": "application/json"
          }
        }
      );
    }
  } catch (error) {
    console.error("Error in sendEveningReminders:", error.response?.data || error.message);
    throw error;
  }
});
