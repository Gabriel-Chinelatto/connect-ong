// Servidor estatico minimo para a verificacao visual por screenshots.
// Uso: dart tool/screenshots/server.dart <pasta build/web> <porta>
// (Chrome headless nao renderiza via file://, precisa de um HTTP real.)
import 'dart:io';

Future<void> main(List<String> args) async {
  final root = args[0];
  final porta = int.parse(args[1]);

  const mimes = {
    'html': 'text/html',
    'js': 'application/javascript',
    'mjs': 'application/javascript',
    'css': 'text/css',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'json': 'application/json',
    'wasm': 'application/wasm',
    'svg': 'image/svg+xml',
    'ico': 'image/x-icon',
    'otf': 'font/otf',
    'ttf': 'font/ttf',
    'frag': 'text/plain',
  };

  final server = await HttpServer.bind('127.0.0.1', porta);
  stdout.writeln('Servindo $root em http://127.0.0.1:$porta');

  await for (final req in server) {
    var caminho = req.uri.path == '/' ? '/index.html' : req.uri.path;
    final arquivo = File('$root$caminho');
    if (await arquivo.exists()) {
      final ext = caminho.split('.').last.toLowerCase();
      req.response.headers.contentType =
          ContentType.parse(mimes[ext] ?? 'application/octet-stream');
      await req.response.addStream(arquivo.openRead());
    } else {
      req.response.statusCode = HttpStatus.notFound;
    }
    await req.response.close();
  }
}
