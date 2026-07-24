/**
 * Chuỗi Xanh Việt — FCM relay worker (Cloudflare Workers, free tier, no card).
 *
 * The mobile app cannot hold an FCM server credential, so it POSTs a
 * topic-targeted push here and this worker forwards it to Firebase Cloud
 * Messaging HTTP v1 using a service account. The service account never
 * leaves Cloudflare (stored as an encrypted secret).
 *
 * Request  (POST /send, header `x-push-key: <PUSH_API_KEY>`):
 *   { "topic": "shop_123", "title": "...", "body": "...",
 *     "link": "/farmer/orders/1", "data": { "k": "v" } }
 *
 * Secrets required (see README.md):
 *   PUSH_API_KEY               shared secret the app sends in x-push-key
 *   FIREBASE_SERVICE_ACCOUNT   the service-account JSON, pasted whole
 */

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return json({ error: 'method_not_allowed' }, 405);
    }
    if (env.PUSH_API_KEY && request.headers.get('x-push-key') !== env.PUSH_API_KEY) {
      return json({ error: 'unauthorized' }, 401);
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return json({ error: 'bad_json' }, 400);
    }

    const { topic, title, body, link, data } = payload || {};
    if (!topic || (!title && !body)) {
      return json({ error: 'missing_topic_or_content' }, 400);
    }

    let account;
    try {
      account = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
    } catch {
      return json({ error: 'service_account_not_configured' }, 500);
    }

    try {
      const accessToken = await getAccessToken(account);
      const message = {
        message: {
          topic: String(topic),
          notification: {
            title: title ? String(title) : undefined,
            body: body ? String(body) : undefined,
          },
          data: buildData(link, data),
          android: { priority: 'high' },
        },
      };
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            authorization: `Bearer ${accessToken}`,
            'content-type': 'application/json',
          },
          body: JSON.stringify(message),
        },
      );
      const text = await res.text();
      return json({ ok: res.ok, status: res.status, fcm: safeParse(text) }, res.ok ? 200 : 502);
    } catch (e) {
      return json({ error: 'send_failed', detail: String(e) }, 500);
    }
  },
};

function buildData(link, data) {
  const out = {};
  if (data && typeof data === 'object') {
    for (const [k, v] of Object.entries(data)) out[k] = String(v);
  }
  if (link) out.link = String(link);
  return out;
}

/** Mints a short-lived OAuth2 access token for the FCM scope via a signed JWT. */
async function getAccessToken(account) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claim))}`;
  const key = await importPrivateKey(account.private_key);
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64urlBytes(new Uint8Array(sig))}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!data.access_token) throw new Error('no_access_token: ' + JSON.stringify(data));
  return data.access_token;
}

async function importPrivateKey(pem) {
  const der = pemToDer(pem);
  return crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

function pemToDer(pem) {
  const b64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const raw = atob(b64);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes.buffer;
}

function b64url(str) {
  return b64urlBytes(new TextEncoder().encode(str));
}

function b64urlBytes(bytes) {
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function safeParse(text) {
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}
