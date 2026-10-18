const MAX_CLOCK_SKEW_SECONDS = 300;

export async function authorizeScheduledRequest(
  request: Request,
  secret: string,
  consumeNonce: (nonce: string, expiresAt: string) => Promise<boolean>,
  now = Date.now(),
): Promise<boolean> {
  if (request.method !== 'POST' || new TextEncoder().encode(secret).length < 32) return false;
  const body = await request.clone().text();
  try {
    const payload = JSON.parse(body);
    if (!payload || payload.mode !== 'fleet' || Object.keys(payload).length !== 1) return false;
  } catch {
    return false;
  }

  const timestamp = request.headers.get('x-simulator-timestamp') ?? '';
  const nonce = request.headers.get('x-simulator-nonce') ?? '';
  const signature = request.headers.get('x-simulator-signature') ?? '';
  if (!/^\d{10}$/.test(timestamp) || !/^[0-9a-f-]{36}$/i.test(nonce) || !/^[0-9a-f]{64}$/i.test(signature)) return false;

  const issued = Number(timestamp);
  const current = Math.floor(now / 1000);
  if (Math.abs(current - issued) > MAX_CLOCK_SKEW_SECONDS) return false;

  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']);
  const signed = new TextEncoder().encode(`${timestamp}.${nonce}.${body}`);
  const sig = Uint8Array.from(signature.match(/.{2}/g)!, (byte) => parseInt(byte, 16));
  if (!await crypto.subtle.verify('HMAC', key, sig, signed)) return false;

  return await consumeNonce(nonce, new Date((issued + MAX_CLOCK_SKEW_SECONDS) * 1000).toISOString());
}
