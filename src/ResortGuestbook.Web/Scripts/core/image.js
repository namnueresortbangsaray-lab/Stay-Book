// Shrinks a photo in the browser before upload: longest side at most `maxSide` px, re-encoded as WebP (JPEG where the
// browser cannot encode WebP). Phone photos of 3–5 MB come out around 100–300 KB and stay readable.
export async function shrinkImage(file, { maxSide = 1600, quality = 0.72 } = {}) {
  const bitmap = await createImageBitmap(file, { imageOrientation: 'from-image' });
  const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext('2d').drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();

  const encode = (type, q) => new Promise(resolve => canvas.toBlob(resolve, type, q));
  let blob = await encode('image/webp', quality);
  if (!blob || blob.type !== 'image/webp') blob = await encode('image/jpeg', quality + 0.03);
  const smaller = blob.size < file.size || !['image/jpeg', 'image/png', 'image/webp'].includes(file.type);
  return smaller
    ? { blob, name: `id-card.${blob.type === 'image/webp' ? 'webp' : 'jpg'}`, width: canvas.width, height: canvas.height }
    : { blob: file, name: file.name, width: canvas.width, height: canvas.height };
}
