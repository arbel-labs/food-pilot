// Edge Function "analyze".
//
// Aplikasi mengirim ringkasan angka yang sudah dihitung di HP. Function ini
// menambahkan kunci Gemini (hanya ada di environment server), memanggil
// model, lalu mengembalikan JSON berskema tetap. Model dilarang menghitung.
//
// Deploy: supabase functions deploy analyze --no-verify-jwt
// Kunci:  supabase secrets set GEMINI_API_KEY=...

import { withSupabase } from 'npm:@supabase/server';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
const GEMINI_MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-3.1-flash-lite';
const MAX_BODY = 20000;

const SYSTEM_ANALISIS = `Kamu konsultan usaha kecil di Indonesia yang bicara sehari-hari.
Aturan keras:
- DILARANG menghitung. Semua angka sudah dihitung aplikasi.
- DILARANG menyebut angka yang tidak ada di data yang dikirim.
- Bahasa Indonesia sehari-hari, tanpa istilah akuntansi.
- Tepat tiga rekomendasi, diurutkan dari yang paling mendesak.
- Tiap tindakan harus bisa dikerjakan pemilik warung minggu ini, sendirian,
  tanpa alat baru.
- headline maksimal 80 karakter, problem 120, action 200, impact 100.`;

const SYSTEM_CAPTION = `Kamu menulis caption promo singkat untuk usaha kecil Indonesia.
Satu paragraf pendek, ramah, tanpa janji berlebihan, maksimal 220 karakter,
boleh dua tagar di akhir. Jawab hanya captionnya, tanpa penjelasan.`;

const SKEMA_ANALISIS = {
  type: 'OBJECT',
  properties: {
    headline: { type: 'STRING' },
    recommendations: {
      type: 'ARRAY',
      minItems: 3,
      maxItems: 3,
      items: {
        type: 'OBJECT',
        properties: {
          problem: { type: 'STRING' },
          action: { type: 'STRING' },
          impact: { type: 'STRING' },
          priority: { type: 'STRING', enum: ['tinggi', 'sedang', 'rendah'] },
        },
        required: ['problem', 'action', 'impact', 'priority'],
      },
    },
  },
  required: ['headline', 'recommendations'],
};

type GeminiPart = { text?: string; thought?: boolean };

async function callGemini(
  system: string,
  user: string,
  schema?: unknown,
): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': GEMINI_API_KEY,
      },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: [{ role: 'user', parts: [{ text: user }] }],
        generationConfig: schema
          ? {
              responseMimeType: 'application/json',
              responseSchema: schema,
              temperature: 0.4,
            }
          : { temperature: 0.9 },
      }),
    },
  );

  if (!response.ok) {
    throw new Error(`Gemini ${response.status}: ${await response.text()}`);
  }

  const data = await response.json();
  const parts: GeminiPart[] = data?.candidates?.[0]?.content?.parts ?? [];
  return parts
    .filter((part) => !part.thought)
    .map((part) => part.text ?? '')
    .join('')
    .trim();
}

function potong(value: unknown, max: number): string {
  const text = typeof value === 'string' ? value.trim() : '';
  return text.length <= max ? text : `${text.slice(0, max - 1).trimEnd()}…`;
}

function rapikanAnalisis(raw: string): Record<string, unknown> {
  const parsed = JSON.parse(raw);
  const list = Array.isArray(parsed?.recommendations)
    ? parsed.recommendations
    : [];
  if (list.length < 3) throw new Error('Model tidak mengembalikan 3 rekomendasi');

  const prioritas = ['tinggi', 'sedang', 'rendah'];
  return {
    headline: potong(parsed?.headline, 80),
    recommendations: list.slice(0, 3).map((item: Record<string, unknown>) => ({
      problem: potong(item?.problem, 120),
      action: potong(item?.action, 200),
      impact: potong(item?.impact, 100),
      priority: prioritas.includes(String(item?.priority))
        ? String(item?.priority)
        : 'sedang',
    })),
  };
}

export default {
  fetch: withSupabase({ auth: 'publishable:*' }, async (req: Request) => {
    if (req.method !== 'POST') {
      return Response.json({ error: 'Gunakan POST' }, { status: 405 });
    }
    if (!GEMINI_API_KEY) {
      return Response.json(
        { error: 'GEMINI_API_KEY belum diisi di secrets' },
        { status: 500 },
      );
    }

    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return Response.json({ error: 'Body bukan JSON' }, { status: 400 });
    }

    const raw = JSON.stringify(body);
    if (raw.length > MAX_BODY) {
      return Response.json({ error: 'Ringkasan terlalu besar' }, { status: 413 });
    }

    try {
      if (body.mode === 'caption') {
        const caption = await callGemini(
          SYSTEM_CAPTION,
          `Data menu (JSON): ${JSON.stringify(body.menu ?? {})}`,
        );
        return Response.json({ caption: potong(caption, 220) });
      }

      const hasil = await callGemini(
        SYSTEM_ANALISIS,
        `Ringkasan usaha (JSON): ${JSON.stringify(body.ringkasan ?? {})}`,
        SKEMA_ANALISIS,
      );
      return Response.json(rapikanAnalisis(hasil));
    } catch (error) {
      console.error(error);
      return Response.json(
        { error: 'Model gagal menjawab', detail: String(error) },
        { status: 502 },
      );
    }
  }),
};
