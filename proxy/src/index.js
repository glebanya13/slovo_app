/**
 * Бесплатный прокси Gemini + ElevenLabs (Cloudflare Workers).
 * Firebase Auth JWT проверяется через публичные JWKS — Blaze не нужен.
 */

const JWKS_URL = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
let jwksCache = { keys: null, expiresAt: 0 };

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type, Accept',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  });
}

function b64urlToBytes(s) {
  const pad = '='.repeat((4 - (s.length % 4)) % 4);
  const b64 = (s + pad).replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function decodeJwtPart(part) {
  return JSON.parse(new TextDecoder().decode(b64urlToBytes(part)));
}

async function loadJwks() {
  const now = Date.now();
  if (jwksCache.keys && now < jwksCache.expiresAt) return jwksCache.keys;
  const res = await fetch(JWKS_URL);
  if (!res.ok) throw new Error('jwks fetch failed');
  const data = await res.json();
  const map = Object.fromEntries((data.keys || []).map((k) => [k.kid, k]));
  const cc = res.headers.get('Cache-Control') || '';
  const m = cc.match(/max-age=(\d+)/);
  const ttl = m ? Number(m[1]) * 1000 : 3600_000;
  jwksCache = { keys: map, expiresAt: now + ttl };
  return map;
}

async function verifyFirebaseToken(token, projectId) {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('bad jwt');
  const header = decodeJwtPart(parts[0]);
  const payload = decodeJwtPart(parts[1]);
  const now = Math.floor(Date.now() / 1000);

  if (header.alg !== 'RS256' || header.typ !== 'JWT') throw new Error('bad header');
  if (!payload.sub || payload.aud !== projectId) throw new Error('bad aud/sub');
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) throw new Error('bad iss');
  if (typeof payload.exp !== 'number' || payload.exp <= now) throw new Error('expired');
  if (typeof payload.iat !== 'number' || payload.iat > now + 60) throw new Error('bad iat');

  const jwks = await loadJwks();
  const jwk = jwks[header.kid];
  if (!jwk) throw new Error('unknown kid');

  const key = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  );
  const ok = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    b64urlToBytes(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!ok) throw new Error('bad signature');
  return payload;
}

async function requireUser(request, env) {
  const header = request.headers.get('Authorization') || '';
  const m = header.match(/^Bearer\s+(.+)$/i);
  if (!m) {
    const err = new Error('Unauthorized');
    err.status = 401;
    throw err;
  }
  try {
    return await verifyFirebaseToken(m[1], env.FIREBASE_PROJECT_ID);
  } catch (_) {
    const err = new Error('Unauthorized');
    err.status = 401;
    throw err;
  }
}

async function handleGemini(request, env) {
  await requireUser(request, env);
  if (!env.GEMINI_API_KEY) return json(500, { error: { message: 'GEMINI_API_KEY not configured' } });

  const body = await request.json();
  const model = body.model || 'gemini-2.5-flash';
  const upstreamBody = { ...body };
  delete upstreamBody.model;

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}` +
    ':streamGenerateContent?alt=sse';

  const upstream = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': env.GEMINI_API_KEY,
    },
    body: JSON.stringify(upstreamBody),
  });

  if (!upstream.ok) {
    const text = await upstream.text();
    return new Response(text || JSON.stringify({ error: { message: 'Upstream error' } }), {
      status: upstream.status,
      headers: { 'Content-Type': 'application/json', ...corsHeaders() },
    });
  }

  return new Response(upstream.body, {
    status: 200,
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      ...corsHeaders(),
    },
  });
}

async function handleTts(request, env) {
  await requireUser(request, env);
  if (!env.ELEVENLABS_API_KEY) return json(500, { error: { message: 'ELEVENLABS_API_KEY not configured' } });

  const body = await request.json();
  const text = (body.text || '').trim();
  if (!text) return json(400, { error: { message: 'Empty text' } });

  const voiceId = body.voiceId || 'OmiN5OoGtndz0F9qqRP1';
  const modelId = body.modelId || 'eleven_flash_v2_5';
  const url =
    `https://api.elevenlabs.io/v1/text-to-speech/${encodeURIComponent(voiceId)}/stream` +
    '?output_format=mp3_22050_32&optimize_streaming_latency=4';

  const upstream = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'audio/mpeg',
      'xi-api-key': env.ELEVENLABS_API_KEY,
    },
    body: JSON.stringify({
      text,
      model_id: modelId,
      voice_settings: { stability: 0.4, similarity_boost: 0.7 },
    }),
  });

  if (!upstream.ok) {
    const textBody = await upstream.text();
    return new Response(textBody || JSON.stringify({ error: { message: 'Upstream error' } }), {
      status: upstream.status,
      headers: { 'Content-Type': 'application/json', ...corsHeaders() },
    });
  }

  return new Response(upstream.body, {
    status: 200,
    headers: { 'Content-Type': 'audio/mpeg', ...corsHeaders() },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const path = new URL(request.url).pathname.replace(/\/+$/, '') || '/';
    try {
      if (request.method === 'POST' && (path === '/geminiStream' || path.endsWith('/geminiStream'))) {
        return await handleGemini(request, env);
      }
      if (request.method === 'POST' && (path === '/tts' || path.endsWith('/tts'))) {
        return await handleTts(request, env);
      }
      return json(404, { error: { message: 'Not found' } });
    } catch (e) {
      if (e && e.status === 401) return json(401, { error: { message: 'Unauthorized' } });
      return json(500, { error: { message: 'Proxy error' } });
    }
  },
};
