import { authorizeScheduledRequest } from './security.ts';

const secret = 'test-only-scheduled-secret-32-byte-minimum';
const body = '{"mode":"fleet"}';
const now = 1_800_000_000_000;

async function request(timestamp = Math.floor(now / 1000), payload = body, key = secret) {
  const nonce = crypto.randomUUID();
  const signed = `${timestamp}.${nonce}.${payload}`;
  const cryptoKey = await crypto.subtle.importKey('raw', new TextEncoder().encode(key), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const digest = new Uint8Array(await crypto.subtle.sign('HMAC', cryptoKey, new TextEncoder().encode(signed)));
  const signature = [...digest].map((byte) => byte.toString(16).padStart(2, '0')).join('');
  return new Request('https://local.test', { method: 'POST', body: payload, headers: {
    'x-simulator-timestamp': String(timestamp), 'x-simulator-nonce': nonce, 'x-simulator-signature': signature,
  } });
}

Deno.test('missing and invalid credentials are rejected without consuming a nonce', async () => {
  let calls = 0;
  const consume = async () => { calls++; return true; };
  const valid = await request();
  const missing = new Request(valid.url, { method: 'POST', body, headers: { 'x-simulator-timestamp': valid.headers.get('x-simulator-timestamp')! } });
  if (await authorizeScheduledRequest(missing, secret, consume, now)) throw new Error('missing auth accepted');
  for (const role of ['rider', 'authenticated-user', 'admin']) {
    const userRequest = new Request(valid.url, { method: 'POST', body, headers: { authorization: `Bearer ${role}-jwt` } });
    if (await authorizeScheduledRequest(userRequest, secret, consume, now)) throw new Error(`${role} JWT accepted without scheduler signature`);
  }
  if (await authorizeScheduledRequest(await request(undefined, body, 'wrong'), secret, consume, now)) throw new Error('invalid signature accepted');
  if (calls !== 0) throw new Error('rejected requests reached nonce storage');
});

Deno.test('expired, malformed, and caller-selected simulation requests are rejected', async () => {
  let calls = 0;
  const consume = async () => { calls++; return true; };
  if (await authorizeScheduledRequest(await request(1), secret, consume, now)) throw new Error('expired request accepted');
  if (await authorizeScheduledRequest(await request(undefined, '{"mode":"test"}'), secret, consume, now)) throw new Error('test mode accepted');
  if (await authorizeScheduledRequest(await request(undefined, '{'), secret, consume, now)) throw new Error('malformed JSON accepted');
  if (await authorizeScheduledRequest(await request(undefined, '{"mode":"fleet","deviceId":"SIM-x","allowReassign":true}'), secret, consume, now)) throw new Error('caller-controlled provisioning fields accepted');
  const get = new Request('https://local.test', { method: 'GET' });
  if (await authorizeScheduledRequest(get, secret, consume, now)) throw new Error('GET accepted');
  if (await authorizeScheduledRequest(await request(), '', consume, now)) throw new Error('missing server secret accepted');
  if (await authorizeScheduledRequest(await request(), 'short-secret', consume, now)) throw new Error('weak server secret accepted');
  if (calls !== 0) throw new Error('rejected requests reached nonce storage');
});

Deno.test('authorized scheduled request consumes a nonce and rejects replay', async () => {
  const used = new Set<string>();
  const consume = async (nonce: string) => !used.has(nonce) && !!used.add(nonce);
  const req = await request();
  if (!await authorizeScheduledRequest(req, secret, consume, now)) throw new Error('scheduled request rejected');
  if (await authorizeScheduledRequest(req, secret, consume, now)) throw new Error('replay accepted');
});
