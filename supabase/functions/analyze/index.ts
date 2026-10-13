// Edge Function "analyze".
//
// Aplikasi mengirim kalimat atau ringkasan angka yang sudah dihitung di HP.
// Function ini menambahkan kunci Gemini (hanya ada di environment server),
// memanggil model, lalu mengembalikan JSON berskema tetap.
//
// Model dilarang menghitung. Untuk mode chat, model hanya menyalin angka
// yang disebut pemilik; keputusan apakah datanya cukup diambil di sini.
//
// Deploy: supabase functions deploy analyze
// Kunci:  supabase secrets set GEMINI_API_KEY=...
// Model:  supabase secrets set GEMINI_MODEL=gemini-2.5-flash

import { withSupabase } from 'npm:@supabase/server';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') ?? '';
const GEMINI_MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-3.8-flash';
const MAX_BODY = 20000;
const MAX_REPLY = 20000;

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

const SYSTEM_CHAT = `Kamu asisten pencatatan untuk pemilik warung kecil di Indonesia.
Tugasmu HANYA menyalin isi kalimat pemilik menjadi data terstruktur.

Aturan keras:
- DILARANG menghitung apa pun. Jangan menjumlah modal, jangan menghitung
  margin, jangan menghitung untung. Aplikasi yang menghitung.
- Salin angka persis seperti yang disebut pemilik. Jangan menambah,
  jangan membulatkan, jangan menebak angka yang tidak disebut.
- Ubah penulisan singkat jadi angka penuh: "10 rb" jadi 10000,
  "2rb" jadi 2000, "1,5 jt" jadi 1500000.
- Kalau harga jual tidak disebut, isi harga_jual dengan 0.
- Kalau bahan tidak disebut, isi bahan dengan array kosong.
- Kalau nama menu tidak terdengar, isi nama dengan string kosong.
- Daftar bahan maksimal 20 baris. Jangan menambah bahan yang tidak disebut.
- Nama menu dan nama bahan ditulis dengan huruf kapital di awal saja.

Contoh:
Kalimat: "tambah jus mangga 10 rb, bahannya air 2 rb sama sirup 4 rb"
Jawaban: {"nama":"Jus mangga","harga_jual":10000,"bahan":[{"nama":"Air","harga":2000},{"nama":"Sirup","harga":4000}]}

Kalimat: "tambah jus mangga, bahannya air sama sirup"
Jawaban: {"nama":"Jus mangga","harga_jual":0,"bahan":[]}

Kalimat: "es teh manis 5000 modalnya teh 500 gula 300"
Jawaban: {"nama":"Es teh manis","harga_jual":5000,"bahan":[{"nama":"Teh","harga":500},{"nama":"Gula","harga":300}]}`;

/// Satu bentuk saja, tanpa cabang aksi. Model cukup menyalin; keputusan
/// cukup atau tidaknya data diambil di rapikanChat.
const SKEMA_CHAT = {
  type: 'OBJECT',
  properties: {
    nama: { type: 'STRING' },
    harga_jual: { type: 'INTEGER' },
    bahan: {
      type: 'ARRAY',
      maxItems: 20,
      items: {
        type: 'OBJECT',
        properties: {
          nama: { type: 'STRING' },
          harga: { type: 'INTEGER' },
        },
        required: ['nama', 'harga'],
      },
    },
  },
  required: ['nama', 'harga_jual', 'bahan'],
};

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

async function panggilSekali(
  system: string,
  user: string,
  schema?: unknown,
  maxTokens = 1024,
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
              temperature: 0.2,
              maxOutputTokens: maxTokens,
            }
          : { temperature: 0.9, maxOutputTokens: maxTokens },
      }),
    },
  );

  if (!response.ok) {
    throw new Error(`Gemini ${response.status}: ${await response.text()}`);
  }

  const data = await response.json();

  // Balasan yang terpotong karena kehabisan token tidak pernah berupa JSON
  // utuh. Lebih baik berhenti di sini daripada menyerahkannya ke JSON.parse.
  const alasan = data?.candidates?.[0]?.finishReason;
  if (alasan && alasan !== 'STOP') {
    throw new Error(`Model berhenti tidak wajar: ${alasan}`);
  }

  const parts: GeminiPart[] = data?.candidates?.[0]?.content?.parts ?? [];
  return parts
    .filter((part) => !part.thought)
    .map((part) => part.text ?? '')
    .join('')
    .trim();
}

/// Gemini sesekali membalas 503 saat modelnya sedang ramai, atau 429 saat
/// kuota per menit tersentuh. Keduanya sementara, jadi dicoba ulang dengan
/// jeda yang makin panjang sebelum menyerah.
async function callGemini(
  system: string,
  user: string,
  schema?: unknown,
  maxTokens = 1024,
): Promise<string> {
  const jeda = [400, 900];
  let terakhir: unknown = new Error('Gemini tidak menjawab');

  for (let i = 0; i <= jeda.length; i++) {
    try {
      return await panggilSekali(system, user, schema, maxTokens);
    } catch (error) {
      terakhir = error;
      const pesan = String(error);
      const bisaDiulang = pesan.includes('503') || pesan.includes('429');
      if (!bisaDiulang || i === jeda.length) break;
      await new Promise((resolve) => setTimeout(resolve, jeda[i]));
    }
  }

  throw terakhir;
}

function potong(value: unknown, max: number): string {
  const text = typeof value === 'string' ? value.trim() : '';
  return text.length <= max ? text : `${text.slice(0, max - 1).trimEnd()}…`;
}

function rupiah(value: unknown): number {
  const angka = Number(value);
  if (!Number.isFinite(angka) || angka < 0) return 0;
  return Math.round(angka);
}

/// Membuang pagar kode markdown kalau model menambahkannya, lalu memastikan
/// hasilnya memang JSON utuh.
function bacaJson(raw: string): Record<string, unknown> {
  if (raw.length > MAX_REPLY) {
    throw new Error(`Balasan model terlalu panjang (${raw.length} karakter)`);
  }

  const bersih = raw
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/```\s*$/, '')
    .trim();

  try {
    return JSON.parse(bersih);
  } catch {
    throw new Error('Balasan model bukan JSON utuh');
  }
}

function rapikanAnalisis(raw: string): Record<string, unknown> {
  const parsed = bacaJson(raw);
  const list = Array.isArray(parsed?.recommendations)
    ? parsed.recommendations
    : [];
  if (list.length < 3) {
    throw new Error('Model tidak mengembalikan 3 rekomendasi');
  }

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

/// Model hanya menyalin. Di sini diputuskan apakah hasilnya layak jadi draf
/// menu, atau justru harus balik bertanya ke pemilik.
function rapikanChat(raw: string): Record<string, unknown> {
  const parsed = bacaJson(raw);

  const nama = potong(parsed?.nama, 60);
  const harga = rupiah(parsed?.harga_jual);
  const bahanMentah = Array.isArray(parsed?.bahan) ? parsed.bahan : [];
  const bahan = bahanMentah
    .slice(0, 20)
    .map((item: Record<string, unknown>) => ({
      nama: potong(item?.nama, 40),
      harga: rupiah(item?.harga),
    }))
    .filter((item: { nama: string }) => item.nama.length > 0);

  if (!nama) {
    return {
      aksi: 'tidak_paham',
      pesan:
        'Aku belum paham menunya apa. Coba tulis seperti ini: tambah es teh ' +
        '5 rb, bahannya teh 500 sama gula 300.',
    };
  }

  // Draf tanpa harga jual tidak berguna dan berbahaya kalau disimpan.
  // Lebih baik balik bertanya daripada mengirim angka nol ke aplikasi.
  if (harga <= 0) {
    return { aksi: 'tanya', pertanyaan: `${nama} dijual berapa?` };
  }

  return { aksi: 'tambah_menu', nama, harga_jual: harga, bahan };
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
      return Response.json(
        { error: 'Permintaan terlalu besar' },
        { status: 413 },
      );
    }

    try {
      if (body.mode === 'chat') {
        const kalimat = String(body.kalimat ?? '').trim();

        // Dua kasus ini tidak perlu memanggil model sama sekali.
        if (kalimat.length === 0) {
          return Response.json({
            aksi: 'tidak_paham',
            pesan: 'Tulis dulu kalimatnya ya.',
          });
        }
        if (kalimat.length > 500) {
          return Response.json({
            aksi: 'tidak_paham',
            pesan: 'Kalimatnya kepanjangan. Coba satu menu dulu.',
          });
        }

        const hasil = await callGemini(
          SYSTEM_CHAT,
          `Kalimat pemilik warung: "${kalimat}"`,
          SKEMA_CHAT,
          800,
        );
        return Response.json(rapikanChat(hasil));
      }

      if (body.mode === 'caption') {
        const caption = await callGemini(
          SYSTEM_CAPTION,
          `Data menu (JSON): ${JSON.stringify(body.menu ?? {})}`,
          undefined,
          400,
        );
        return Response.json({ caption: potong(caption, 220) });
      }

      const hasil = await callGemini(
        SYSTEM_ANALISIS,
        `Ringkasan usaha (JSON): ${JSON.stringify(body.ringkasan ?? {})}`,
        SKEMA_ANALISIS,
        1500,
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