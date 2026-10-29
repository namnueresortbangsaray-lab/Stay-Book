<?php

declare(strict_types=1);

namespace App\Http\Controllers\Web;

use App\Core\Config;
use App\Core\Request;
use App\Core\Response;
use App\Repositories\Contracts\ResortRepositoryInterface;

final class UploadController
{
    public function __construct(private readonly ResortRepositoryInterface $repository)
    {
    }

    public function download(Request $request): Response
    {
        $item = $this->repository->attachment((string) $request->param('id'));
        if ($item === null) {
            return Response::json(null, 'ไม่พบไฟล์', 404);
        }
        $name = preg_replace('/[^\pL\pN._ -]+/u', '_', (string) $item['original_name']) ?: 'download';
        if (PHP_SAPI === 'cli-server') {
            $path = (string) Config::get('uploads.path') . '/' . $item['stored_name'];
            $body = is_file($path) ? file_get_contents($path) : false;
            if (!is_string($body)) {
                return Response::json(null, 'ไม่พบไฟล์', 404);
            }
            return Response::raw($body, (string) $item['mime_type'], ['Content-Disposition' => 'attachment; filename="' . addslashes($name) . '"']);
        }
        return Response::raw('', (string) $item['mime_type'], ['X-Accel-Redirect' => '/_protected_uploads/' . $item['stored_name'], 'Content-Disposition' => 'attachment; filename="' . addslashes($name) . '"', 'Content-Length' => (string) $item['size_bytes']]);
    }
}
