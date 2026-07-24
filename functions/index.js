/**
 * Chuỗi Xanh Việt — FCM relay (Firebase Cloud Functions).
 *
 * Drop-in replacement for `push-worker/`: same request contract, so the app
 * needs no code change — only `PUSH_ENDPOINT` has to point here.
 *
 * Unlike the Cloudflare worker this needs no service-account JSON: the Admin
 * SDK already runs with the project's own credentials, so nothing secret is
 * stored or shipped anywhere.
 *
 * Request (POST, header `x-push-key: <PUSH_API_KEY>`):
 *   { "topic": "shop_123", "title": "...", "body": "...",
 *     "link": "/farmer/orders/1", "data": { "k": "v" } }
 */

const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const pushApiKey = defineSecret('PUSH_API_KEY');

exports.send = onRequest(
  { region: 'asia-southeast1', secrets: [pushApiKey], cors: false },
  async (req, res) => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'method_not_allowed' });
    }

    const expectedKey = pushApiKey.value();
    if (expectedKey && req.get('x-push-key') !== expectedKey) {
      return res.status(401).json({ error: 'unauthorized' });
    }

    // onRequest already parses JSON bodies; a non-object means bad input.
    const payload = req.body;
    if (!payload || typeof payload !== 'object') {
      return res.status(400).json({ error: 'bad_json' });
    }

    const { topic, title, body, link, data } = payload;
    if (!topic || (!title && !body)) {
      return res.status(400).json({ error: 'missing_topic_or_content' });
    }

    const notification = {};
    if (title) notification.title = String(title);
    if (body) notification.body = String(body);

    try {
      const messageId = await admin.messaging().send({
        topic: String(topic),
        notification,
        data: buildData(link, data),
        android: { priority: 'high' },
      });
      return res.status(200).json({ ok: true, messageId });
    } catch (e) {
      return res
        .status(500)
        .json({ error: 'send_failed', detail: String(e && e.message) });
    }
  },
);

/** FCM data payloads must be flat string→string. */
function buildData(link, data) {
  const out = {};
  if (data && typeof data === 'object') {
    for (const [k, v] of Object.entries(data)) out[k] = String(v);
  }
  if (link) out.link = String(link);
  return out;
}
