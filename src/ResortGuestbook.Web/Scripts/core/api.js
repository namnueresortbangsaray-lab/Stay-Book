const token = document.querySelector('meta[name="csrf-token"]')?.content ?? '';

export async function api(path, options = {}) {
  const headers = new Headers(options.headers || {});
  headers.set('Accept', 'application/json');
  headers.set('X-CSRF-Token', token);
  if (options.body && !(options.body instanceof FormData)) headers.set('Content-Type', 'application/json');
  const response = await fetch(path, {...options, headers});
  if (response.status === 401) { window.location.assign('/login'); throw new Error('กรุณาเข้าสู่ระบบ'); }
  const payload = await response.json();
  if (!response.ok || !payload.success) {
    const error = new Error(payload.message || 'เกิดข้อผิดพลาด');
    error.errors = payload.errors || {};
    throw error;
  }
  return payload.data;
}
