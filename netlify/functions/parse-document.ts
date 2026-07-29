import type { Config, Context } from "@netlify/functions";
import { GoogleGenAI } from "@google/genai";

type ParseBody = {
  mimeType?: string;
  dataBase64?: string;
  hint?: string;
};

const ALLOWED_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
  "application/pdf",
]);

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
    },
  });
}

export default async (req: Request, _context: Context) => {
  if (req.method === "OPTIONS") {
    return json(204, {});
  }
  if (req.method !== "POST") {
    return json(405, { error: "Method not allowed" });
  }

  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ") || auth.length < 20) {
    return json(401, { error: "Sign in required" });
  }

  let body: ParseBody;
  try {
    body = (await req.json()) as ParseBody;
  } catch {
    return json(400, { error: "Invalid JSON body" });
  }

  const mimeType = (body.mimeType ?? "").toLowerCase().trim();
  const dataBase64 = (body.dataBase64 ?? "").replace(/^data:[^;]+;base64,/, "");
  if (!ALLOWED_MIME.has(mimeType) || dataBase64.length < 32) {
    return json(400, {
      error: "Send an image (JPEG/PNG/WebP) or PDF as base64 with mimeType",
    });
  }

  // Soft size guard (~4MB decoded)
  if (dataBase64.length > 5_500_000) {
    return json(413, { error: "File too large (max ~4MB)" });
  }

  const today = new Date().toISOString().slice(0, 10);
  const hint = (body.hint ?? "").trim().slice(0, 200);

  const prompt = `You extract structured family-organizer data from a photo or PDF (receipt, invitation, school notice, appointment card, flyer).
Today's date is ${today} (use this to resolve relative dates like "tomorrow" or weekday-only dates).
${hint ? `User hint: ${hint}` : ""}

Return ONLY valid JSON (no markdown) with this shape:
{
  "kind": "event" | "expense" | "task" | "unknown",
  "confidence": number between 0 and 1,
  "title": string,
  "startsAt": string | null (ISO-8601 local-ish datetime if known),
  "endsAt": string | null,
  "allDay": boolean,
  "location": string | null,
  "amount": number | null (receipt total if present),
  "currency": string | null (e.g. "USD"),
  "category": string | null,
  "notes": string | null,
  "summary": string (one short sentence of what you saw)
}

Rules:
- Prefer kind "event" for invitations, appointments, school/sports schedules.
- Prefer kind "expense" for store receipts with a clear total.
- Prefer kind "task" for todo-like notes without a firm datetime.
- If unsure of datetime, set startsAt to null and allDay false.
- Do not invent a title; use the clearest label from the document.`;

  try {
    const ai = new GoogleGenAI({});
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: [
        {
          role: "user",
          parts: [
            { text: prompt },
            { inlineData: { mimeType, data: dataBase64 } },
          ],
        },
      ],
      config: {
        temperature: 0.2,
        responseMimeType: "application/json",
      },
    });

    const text = response.text?.trim() ?? "";
    if (!text) {
      return json(502, { error: "Model returned an empty response" });
    }

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(text) as Record<string, unknown>;
    } catch {
      const match = text.match(/\{[\s\S]*\}/);
      if (!match) {
        return json(502, { error: "Model returned non-JSON", raw: text.slice(0, 400) });
      }
      parsed = JSON.parse(match[0]) as Record<string, unknown>;
    }

    return json(200, { draft: parsed });
  } catch (error) {
    const message = error instanceof Error ? error.message : "AI request failed";
    const lower = message.toLowerCase();
    if (
      lower.includes("api key") ||
      lower.includes("unauthenticated") ||
      lower.includes("permission") ||
      lower.includes("credential") ||
      lower.includes("ai gateway")
    ) {
      return json(500, {
        error:
          "AI Gateway is not enabled. Open Netlify site settings → AI Gateway, then retry.",
      });
    }
    return json(500, { error: message });
  }
};

export const config: Config = {
  path: "/api/parse-document",
  method: ["POST", "OPTIONS"],
};
