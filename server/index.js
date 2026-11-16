const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.PORT || process.env.SERVER_PORT || 3000;
const ADMIN_KEY = process.env.ADMIN_KEY || 'admin123';
const FILE = process.env.DATA_FILE || path.join(__dirname, 'data.json');
const ONLINE_MS = 150000;

// شش کانفیگ پیش‌فرض (فقط وقتی دیتابیس خالی است ساخته می‌شوند)
const DEFAULT_CONFIGS = [
  {
    "name": "VLESS • XHTTP Reality",
    "link": "vless://27168be6-fb08-4fec-8b67-4bdcfe8f41d3@16.171.159.75:443?encryption=none&extra=%7B%22mode%22%3A%22auto%22%2C%22xPaddingBytes%22%3A%22100-1000%22%7D&fp=chrome&host=&mode=auto&path=%2Fad&pbk=n6Dq3RzIH4oGlnDWl5vz0Ad9rnYK5vtDTs2B4gCsJmQ&security=reality&sid=257f2adb&sni=www.amazonaws-china.com&nex=%2F0905412996ce16a&support-x25519mlkem768=true&type=xhttp&x_padding_bytes=100-1000#%F0%9D%99%91%F0%9D%99%87%F0%9D%99%80%F0%9D%99%80%F0%9D%99%8E-%F0%9D%99%93%F0%9D%99%83%F0%9D%99%8F%F0%9D%99%8F%F0%9D%99%8B-%D8%A7%D9%BE%D9%84%DB%8C%DA%A9%DB%8C%D8%B4%D9%86"
  },
  {
    "name": "VMESS • gRPC",
    "link": "vmess://ewogICJhZGQiOiAiMTYuMTcxLjE1OS43NSIsCiAgImF1dGhvcml0eSI6ICIiLAogICJpZCI6ICIyNzE2OGJlNi1mYjA4LTRmZWMtOGI2Ny00YmRjZmU4ZjQxZDMiLAogICJuZXQiOiAiZ3JwYyIsCiAgInBhdGgiOiAiIiwKICAicG9ydCI6IDgwLAogICJwcyI6ICLwnZmR8J2ZiPCdmYDwnZmA8J2Zji3wnZmC8J2ZjfCdmYvwnZi+Ldin2b7ZhNuM2qnbjNi02YYiLAogICJzY3kiOiAiYXV0byIsCiAgInRscyI6ICJub25lIiwKICAidHlwZSI6ICJub25lIiwKICAidiI6ICIyIgp9"
  },
  {
    "name": "TROJAN • mKCP",
    "link": "trojan://mpX9dTBiNoBxG0N4pZZ8I5V%2BTWIQNe%2FkJe3t11N1eq4%3D@16.171.159.75:2053?fm=%7B%22udp%22%3A%5B%7B%22settings%22%3A%7B%22header%22%3A%22%22%2C%22value%22%3A%22%22%7D%2C%22type%22%3A%22mkcp-legacy%22%7D%5D%7D&mtu=1350&security=none&tti=20&type=kcp#%F0%9D%99%8F%F0%9D%99%8A%F0%9D%99%8D%F0%9D%99%85%F0%9D%98%BC%F0%9D%99%89-%F0%9D%99%88%F0%9D%99%86%F0%9D%98%BE%F0%9D%99%8B-%D8%A7%D9%BE%D9%84%DB%8C%DA%A9%DB%8C%D8%B4%D9%86"
  },
  {
    "name": "Shadowsocks 2022",
    "link": "ss://2022-blake3-aes-256-gcm:SWePBmNSadMUzbm7GigoCTrCXr1vG%2FzUfYbBDaxk%2FVU%3D:mpX9dTBiNoBxG0N4pZZ8I5V%2BTWIQNe%2FkJe3t11N1eq4%3D@16.171.159.75:8080?type=tcp#%F0%9D%99%8E%F0%9D%99%83%F0%9D%98%BC%F0%9D%98%BF%F0%9D%99%8A%F0%9D%99%92%F0%9D%99%8E%F0%9D%99%8A%F0%9D%98%BE%F0%9D%99%86%F0%9D%99%8E-%D8%A7%D9%BE%D9%84%DB%8C%DA%A9%DB%8C%D8%B4%D9%86"
  },
  {
    "name": "VLESS • WebSocket",
    "link": "vless://27168be6-fb08-4fec-8b67-4bdcfe8f41d3@16.171.159.75:21087?encryption=none&host=&path=%2F&security=none&type=ws#%F0%9D%99%92%F0%9D%99%80%F0%9D%98%BD%F0%9D%99%8E%F0%9D%99%8A%F0%9D%98%BE%F0%9D%99%86%F0%9D%99%80%F0%9D%99%8F-%D8%A7%D9%BE%D9%84%DB%8C%DA%A9%DB%8C%D8%B4%D9%86"
  },
  {
    "name": "VMESS • HTTPUpgrade",
    "link": "vmess://ewogICJhZGQiOiAiMTYuMTcxLjE1OS43NSIsCiAgImhvc3QiOiAiIiwKICAiaWQiOiAiMjcxNjhiZTYtZmIwOC00ZmVjLThiNjctNGJkY2ZlOGY0MWQzIiwKICAibmV0IjogImh0dHB1cGdyYWRlIiwKICAicGF0aCI6ICIvIiwKICAicG9ydCI6IDE2NzUxLAogICJwcyI6ICLwnZmD8J2Zj/CdmY/wnZmL8J2ZkPCdmYvwnZmC8J2ZjfCdmLzwnZi/8J2ZgC3Yp9m+2YTbjNqp24zYtNmGIiwKICAic2N5IjogImF1dG8iLAogICJ0bHMiOiAibm9uZSIsCiAgInR5cGUiOiAibm9uZSIsCiAgInYiOiAiMiIKfQ=="
  }
];

let db = { users: {}, configs: [], events: [], totals: null, agg: null, seeded: false };
try {
  db = Object.assign(db, JSON.parse(fs.readFileSync(FILE, 'utf8')));
} catch (e) {}

// ---------- آمار تجمعی (با پاک شدن events خراب نمی‌شود) ----------
function emptyAgg() {
  return { protocols: {}, transports: {}, countries: {}, days: {} };
}
function migrateStats() {
  if (db.totals && db.agg) return;
  db.totals = { connections: 0, up: 0, down: 0, seconds: 0 };
  db.agg = emptyAgg();
  db.events.forEach((e) => {
    if (e.type === 'connect') {
      db.totals.connections++;
      count(db.agg.protocols, e.protocol);
      count(db.agg.transports, e.transport);
      count(db.agg.countries, e.country);
      count(db.agg.days, dayKey(e.t));
    }
    if (e.type === 'disconnect') {
      db.totals.up += e.up || 0;
      db.totals.down += e.down || 0;
      db.totals.seconds += e.seconds || 0;
    }
  });
}

function dayKey(t) {
  return new Date(t).toISOString().slice(0, 10);
}

let timer = null;
function save() {
  clearTimeout(timer);
  timer = setTimeout(() => {
    const tmp = FILE + '.tmp';
    fs.writeFile(tmp, JSON.stringify(db), (err) => {
      if (!err) fs.rename(tmp, FILE, () => {});
    });
  }, 500);
}

function send(res, code, obj) {
  res.writeHead(code, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-headers': '*',
    'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS'
  });
  res.end(JSON.stringify(obj));
}

function readBody(req) {
  return new Promise((resolve) => {
    let b = '';
    req.on('data', (c) => {
      b += c;
      if (b.length > 2e6) req.destroy();
    });
    req.on('end', () => {
      try {
        resolve(JSON.parse(b || '{}'));
      } catch (e) {
        resolve({});
      }
    });
  });
}

function count(map, key) {
  if (!key) return;
  map[key] = (map[key] || 0) + 1;
}

function top(map) {
  return Object.entries(map)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);
}

// ---------- تحلیل لینک کانفیگ ----------
const SUPPORTED = ['vless', 'vmess', 'trojan', 'ss'];

function b64decode(s) {
  const t = String(s).trim().replace(/-/g, '+').replace(/_/g, '/');
  const pad = t + '='.repeat((4 - (t.length % 4)) % 4);
  return Buffer.from(pad, 'base64').toString('utf8');
}

function safeDecode(s) {
  try {
    return decodeURIComponent(s);
  } catch (e) {
    return s;
  }
}

// خروجی: { protocol, transport, security, name } یا null اگر لینک معتبر نیست
function describeLink(link) {
  const l = String(link).trim();
  const idx = l.indexOf('://');
  if (idx < 0) return null;
  const scheme = l.slice(0, idx).toLowerCase();
  if (!SUPPORTED.includes(scheme)) return null;
  try {
    if (scheme === 'vmess') {
      const body = l.slice(idx + 3).split('#')[0];
      const m = JSON.parse(b64decode(body));
      if (!m.add || !m.id || !m.port) return null;
      return {
        protocol: 'vmess',
        transport: String(m.net || 'tcp'),
        security: m.tls === 'tls' ? 'tls' : 'none',
        name: String(m.ps || '')
      };
    }
    const u = new URL(l);
    if (!u.hostname || !u.port) return null;
    const q = u.searchParams;
    const name = safeDecode(u.hash.replace(/^#/, ''));
    if (scheme === 'ss') {
      return { protocol: 'ss', transport: q.get('type') || 'tcp', security: q.get('security') || 'none', name };
    }
    if (!u.username) return null;
    return {
      protocol: scheme,
      transport: q.get('type') || 'tcp',
      security: q.get('security') || (scheme === 'trojan' ? 'tls' : 'none'),
      name
    };
  } catch (e) {
    return null;
  }
}

function linkKey(link) {
  return String(link).trim().split('#')[0];
}

function extractLinks(text) {
  let t = String(text || '').trim();
  if (!t) return { links: [], unsupported: 0 };
  if (!/:\/\//.test(t)) {
    try {
      const d = b64decode(t.replace(/\s+/g, ''));
      if (/:\/\//.test(d)) t = d;
    } catch (e) {}
  }
  const found = t.match(/[a-z0-9]+:\/\/[^\s"'<>]+/gi) || [];
  const links = [];
  let unsupported = 0;
  found.forEach((f) => {
    const scheme = f.slice(0, f.indexOf('://')).toLowerCase();
    if (scheme === 'http' || scheme === 'https') return;
    if (!SUPPORTED.includes(scheme)) {
      unsupported++;
      return;
    }
    links.push(f.replace(/[,;]+$/, ''));
  });
  return { links, unsupported };
}

async function fetchSub(url) {
  const ctl = new AbortController();
  const to = setTimeout(() => ctl.abort(), 20000);
  try {
    const r = await fetch(url, { signal: ctl.signal, headers: { 'user-agent': 'v2rayN/7.0 Parham' } });
    if (!r.ok) throw new Error('sub http ' + r.status);
    const body = await r.text();
    const info = {};
    const h = r.headers.get('subscription-userinfo');
    if (h) {
      h.split(';').forEach((p) => {
        const [k, v] = p.split('=').map((x) => (x || '').trim());
        if (k) info[k] = Number(v) || 0;
      });
    }
    return { body, info };
  } finally {
    clearTimeout(to);
  }
}

function pad2(n) {
  return String(n).padStart(2, '0');
}

// ---------- لوکیشن هر کانفیگ (از روی آدرس سرور؛ ادمین هم می‌تواند دستی عوض کند) ----------
function hostOf(link) {
  try {
    const l = String(link).trim();
    const idx = l.indexOf('://');
    const scheme = l.slice(0, idx).toLowerCase();
    if (scheme === 'vmess') {
      const m = JSON.parse(b64decode(l.slice(idx + 3).split('#')[0]));
      return String(m.add || '');
    }
    return new URL(l).hostname;
  } catch (e) {
    return '';
  }
}

async function lookupLocation(host) {
  if (!host) return null;
  const ctl = new AbortController();
  const to = setTimeout(() => ctl.abort(), 8000);
  try {
    const r = await fetch('https://ipwho.is/' + encodeURIComponent(host), { signal: ctl.signal });
    const j = await r.json();
    if (j && j.success !== false && j.country) return { country: String(j.country), code: String(j.country_code || '') };
  } catch (e) {
  } finally {
    clearTimeout(to);
  }
  return null;
}

let locBusy = false;
async function fillLocations() {
  if (locBusy) return;
  locBusy = true;
  try {
    const cache = {};
    for (const c of db.configs) {
      if (c.country) continue;
      const h = hostOf(c.link);
      if (!h) continue;
      if (!(h in cache)) cache[h] = await lookupLocation(h);
      if (cache[h]) {
        c.country = cache[h].country;
        c.code = cache[h].code;
        save();
      }
    }
  } finally {
    locBusy = false;
  }
}

function addConfig(link, opts) {
  const d = describeLink(link);
  if (!d) return null;
  const c = {
    id: crypto.randomBytes(4).toString('hex'),
    name: (opts.name || d.name || d.protocol.toUpperCase() + ' ' + d.transport).slice(0, 80),
    quotaGb: opts.quotaGb != null ? Number(opts.quotaGb) || 0 : 0,
    expires: opts.expires || '',
    link: String(link).trim(),
    protocol: d.protocol,
    transport: d.transport,
    security: d.security,
    source: opts.source || 'manual',
    country: opts.country || '',
    code: opts.code || '',
    enabled: true
  };
  db.configs.push(c);
  return c;
}

function seedDefaults() {
  if (db.seeded || db.configs.length) {
    db.seeded = true;
    return;
  }
  DEFAULT_CONFIGS.forEach((x) => addConfig(x.link, { name: x.name, source: 'default' }));
  db.seeded = true;
  save();
}

async function importText(b) {
  let text = String(b.text || '').trim();
  if (!text) throw new Error('متن خالی است');
  let source = 'manual';
  let info = {};
  const urls = text.match(/^https?:\/\/\S+$/i);
  if (urls) {
    source = text;
    const r = await fetchSub(text);
    text = r.body;
    info = r.info;
  }
  const { links, unsupported } = extractLinks(text);
  const have = new Set(db.configs.map((c) => linkKey(c.link)));
  let quotaGb = b.quotaGb != null && b.quotaGb !== '' ? Number(b.quotaGb) : null;
  let expires = b.expires || '';
  if (info.total && quotaGb == null) quotaGb = Math.round((info.total / 1073741824) * 100) / 100;
  if (info.expire && !expires) {
    const e = new Date(info.expire * 1000);
    expires = e.getUTCFullYear() + '/' + pad2(e.getUTCMonth() + 1) + '/' + pad2(e.getUTCDate());
  }
  let added = 0;
  let duplicates = 0;
  let invalid = 0;
  const items = [];
  links.forEach((l, i) => {
    const k = linkKey(l);
    if (have.has(k)) {
      duplicates++;
      return;
    }
    const nm = b.name ? (links.length > 1 ? b.name + ' ' + (i + 1) : b.name) : '';
    const c = addConfig(l, { name: nm, quotaGb, expires, source });
    if (!c) {
      invalid++;
      return;
    }
    have.add(k);
    added++;
    items.push({ id: c.id, name: c.name, protocol: c.protocol, transport: c.transport });
  });
  if (added) {
    save();
    fillLocations();
  }
  return { added, duplicates, invalid, unsupported, found: links.length, items };
}

function pickConfig(user) {
  const active = db.configs.filter((c) => c.enabled !== false);
  if (!active.length) return null;
  const current = active.find((c) => c.id === user.configId);
  if (current) return current;
  const usage = {};
  Object.values(db.users).forEach((u) => count(usage, u.configId));
  active.sort((a, b) => (usage[a.id] || 0) - (usage[b.id] || 0));
  user.configId = active[0].id;
  return active[0];
}

const ID_RE = /^[a-f0-9]{16,64}$/;

function touch(id, platform) {
  if (!ID_RE.test(String(id || ''))) return null;
  const now = Date.now();
  if (!db.users[id]) {
    db.users[id] = {
      id,
      platform: platform || 'unknown',
      firstSeen: now,
      lastSeen: now,
      connections: 0,
      up: 0,
      down: 0,
      seconds: 0,
      connected: false,
      lastProtocol: '',
      lastCountry: '',
      configId: '',
      openSession: '',
      lastClosedSession: ''
    };
  }
  const u = db.users[id];
  u.lastSeen = now;
  if (platform) u.platform = String(platform).slice(0, 20);
  return u;
}

function isOnline(u, now) {
  return !!u.connected && now - u.lastSeen < ONLINE_MS;
}

function stats() {
  const now = Date.now();
  const users = Object.values(db.users);
  const platforms = {};
  users.forEach((u) => count(platforms, u.platform));
  const last7 = [];
  for (let i = 6; i >= 0; i--) {
    const d = dayKey(now - i * 86400000);
    last7.push({ name: d.slice(5), value: db.agg.days[d] || 0 });
  }
  const online = users.filter((u) => isOnline(u, now)).length;
  const activeToday = users.filter((u) => now - u.lastSeen < 86400000).length;
  const everConnected = users.filter((u) => u.connections > 0).length;
  const newToday = users.filter((u) => now - u.firstSeen < 86400000).length;
  const topCountries = top(db.agg.countries);
  const topProtocols = top(db.agg.protocols);
  return {
    totalUsers: users.length,
    everConnected,
    newToday,
    online,
    activeToday,
    connections: db.totals.connections,
    up: db.totals.up,
    down: db.totals.down,
    seconds: db.totals.seconds,
    protocols: topProtocols,
    transports: top(db.agg.transports),
    countries: topCountries,
    platforms: top(platforms),
    bestLocation: topCountries[0] ? topCountries[0].name : '',
    bestProtocol: topProtocols[0] ? topProtocols[0].name : '',
    last7,
    configs: db.configs.length,
    configsActive: db.configs.filter((c) => c.enabled !== false).length
  };
}

function publicConfig(c) {
  return {
    id: c.id,
    name: c.name,
    quotaGb: c.quotaGb,
    expires: c.expires,
    link: c.link,
    protocol: c.protocol || '',
    transport: c.transport || '',
    country: c.country || '',
    code: c.code || ''
  };
}

function usersPerConfig() {
  const now = Date.now();
  const m = {};
  Object.values(db.users).forEach((u) => {
    if (!u.configId) return;
    if (!m[u.configId]) m[u.configId] = { users: 0, online: 0 };
    m[u.configId].users++;
    if (isOnline(u, now)) m[u.configId].online++;
  });
  return m;
}

const server = http.createServer(async (req, res) => {
  try {
    await handle(req, res);
  } catch (e) {
    console.error(e);
    try {
      send(res, 500, { error: String((e && e.message) || e) });
    } catch (x) {}
  }
});

async function handle(req, res) {
  if (req.method === 'OPTIONS') return send(res, 204, {});
  const url = new URL(req.url, 'http://x');
  const p = url.pathname;

  if (p === '/' || p === '/health') return send(res, 200, { ok: true, name: 'parham-server' });

  if (p.startsWith('/api/admin/')) {
    if (req.headers['x-admin-key'] !== ADMIN_KEY) return send(res, 401, { error: 'unauthorized' });

    if (p === '/api/admin/stats') return send(res, 200, stats());

    if (p === '/api/admin/users') {
      const now = Date.now();
      const list = Object.values(db.users)
        .map((u) => Object.assign({}, u, { online: isOnline(u, now) }))
        .sort((a, b) => b.lastSeen - a.lastSeen);
      return send(res, 200, list);
    }

    if (p === '/api/admin/configs' && req.method === 'GET') {
      const per = usersPerConfig();
      return send(
        res,
        200,
        db.configs.map((c) => Object.assign({}, c, { users: (per[c.id] || {}).users || 0, online: (per[c.id] || {}).online || 0 }))
      );
    }

    // افزودن کانفیگ، چند کانفیگ یا لینک ساب (http/https)؛ کانفیگ‌ها خودکار استخراج می‌شوند
    if (p === '/api/admin/import' && req.method === 'POST') {
      const b = await readBody(req);
      try {
        return send(res, 200, await importText(b));
      } catch (e) {
        return send(res, 400, { error: String((e && e.message) || e) });
      }
    }

    if (p === '/api/admin/configs' && req.method === 'POST') {
      const b = await readBody(req);
      if (!b.link) return send(res, 400, { error: 'link required' });
      const c = addConfig(b.link, { name: b.name, quotaGb: b.quotaGb, expires: b.expires });
      if (!c) return send(res, 400, { error: 'لینک کانفیگ معتبر نیست' });
      save();
      fillLocations();
      return send(res, 200, c);
    }

    const m = p.match(/^\/api\/admin\/configs\/([a-f0-9]+)$/);
    if (m) {
      const idx = db.configs.findIndex((c) => c.id === m[1]);
      if (idx < 0) return send(res, 404, { error: 'not found' });
      if (req.method === 'DELETE') {
        db.configs.splice(idx, 1);
        save();
        return send(res, 200, { ok: true });
      }
      if (req.method === 'PUT') {
        const b = await readBody(req);
        Object.assign(db.configs[idx], b, { id: m[1] });
        if (b.country != null) db.configs[idx].country = String(b.country).slice(0, 60);
        if (b.code != null) db.configs[idx].code = String(b.code).slice(0, 2).toUpperCase();
        if (b.link && b.country == null) {
          db.configs[idx].country = '';
          db.configs[idx].code = '';
          fillLocations();
        }
        if (b.link) {
          const d = describeLink(b.link);
          if (d) Object.assign(db.configs[idx], { protocol: d.protocol, transport: d.transport, security: d.security });
        }
        save();
        return send(res, 200, db.configs[idx]);
      }
    }

    if (p === '/api/admin/events') return send(res, 200, db.events.slice(-200).reverse());

    return send(res, 404, { error: 'not found' });
  }

  if (p === '/api/servers') {
    return send(
      res,
      200,
      db.configs.filter((c) => c.enabled !== false).map((c) => ({ id: c.id, name: c.name, country: c.country || '', code: c.code || '' }))
    );
  }

  // لیست همه کانفیگ‌های فعال برای اپ کاربر (تست خودکار و انتخاب سرور)
  if (p === '/api/configs' && req.method === 'GET') {
    const user = touch(url.searchParams.get('deviceId'), url.searchParams.get('platform'));
    if (!user) return send(res, 400, { error: 'deviceId invalid' });
    save();
    return send(res, 200, db.configs.filter((c) => c.enabled !== false).map(publicConfig));
  }

  if (p === '/api/config' && req.method === 'GET') {
    const user = touch(url.searchParams.get('deviceId'), url.searchParams.get('platform'));
    if (!user) return send(res, 400, { error: 'deviceId invalid' });
    const wanted = url.searchParams.get('id');
    let cfg = null;
    if (wanted) cfg = db.configs.find((c) => c.id === wanted && c.enabled !== false);
    if (!cfg) cfg = pickConfig(user);
    if (cfg) user.configId = cfg.id;
    save();
    if (!cfg) return send(res, 404, { error: 'no config' });
    return send(res, 200, publicConfig(cfg));
  }

  if (p === '/api/event' && req.method === 'POST') {
    const b = await readBody(req);
    const u = touch(b.deviceId, b.platform);
    if (!u) return send(res, 400, { error: 'deviceId invalid' });
    const now = Date.now();
    if (b.type === 'connect') {
      const sid = String(b.session || '');
      // رویداد تکراری همان نشست دوباره شمرده نمی‌شود
      if (!(sid && u.openSession === sid)) {
        u.connections++;
        u.openSession = sid;
        db.totals.connections++;
        count(db.agg.protocols, b.protocol);
        count(db.agg.transports, b.transport);
        count(db.agg.countries, b.country);
        count(db.agg.days, dayKey(now));
        db.events.push({
          t: now,
          type: 'connect',
          deviceId: b.deviceId,
          protocol: b.protocol || '',
          transport: b.transport || '',
          country: b.country || ''
        });
      }
      u.connected = true;
      u.lastProtocol = String(b.protocol || '');
      u.lastCountry = String(b.country || '');
      if (b.configId && db.configs.some((c) => c.id === b.configId)) u.configId = b.configId;
    } else if (b.type === 'disconnect') {
      const sid = String(b.session || '');
      u.connected = false;
      if (!(sid && u.lastClosedSession === sid)) {
        const up = Math.max(0, Number(b.up) || 0);
        const down = Math.max(0, Number(b.down) || 0);
        const seconds = Math.max(0, Number(b.seconds) || 0);
        u.up += up;
        u.down += down;
        u.seconds += seconds;
        db.totals.up += up;
        db.totals.down += down;
        db.totals.seconds += seconds;
        u.lastClosedSession = sid;
        u.openSession = '';
        db.events.push({ t: now, type: 'disconnect', deviceId: b.deviceId, up, down, seconds });
      }
    } else if (b.type === 'ping') {
      u.connected = true;
    }
    if (db.events.length > 5000) db.events.splice(0, db.events.length - 5000);
    // فقط ۶۰ روز اخیر نگه داشته می‌شود
    const keys = Object.keys(db.agg.days).sort();
    while (keys.length > 60) delete db.agg.days[keys.shift()];
    save();
    return send(res, 200, { ok: true });
  }

  send(res, 404, { error: 'not found' });
}

migrateStats();
seedDefaults();
fillLocations();
server.listen(PORT, '0.0.0.0', () => console.log('parham-server listening on ' + PORT + ' | configs: ' + db.configs.length));
