import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';

import 'base_ejs_solver.dart';
import 'ejs.dart';

class DenoEJSSolver extends BaseEJSSolver {
  final _DenoProcess _deno;

  DenoEJSSolver._(this._deno);

  static Future<DenoEJSSolver> init({String? denoExe}) async {
    final modules = await EJSBuilder.getJSModules();
    final deno = await _DenoProcess.init(initCode: modules, denoExe: denoExe);
    return DenoEJSSolver._(deno);
  }

  @override
  Future<String> executeJavaScript(String jsCode) async {
    final filePath = path.join((_deno.tmpDir.path),
        'ejs_output_${DateTime.now().microsecondsSinceEpoch}.txt');

    // Wrap the call into a write to file
    final wrappedCode = 'await Deno.writeTextFile("$filePath", $jsCode);';

    final result = await _deno.eval(wrappedCode);

    if (result != "undefined") {
      throw Exception('Expected undefined result from Deno eval, got: $result');
    }

    final file = File(filePath);
    return await file.readAsString();
  }

  @override
  void dispose() {
    _deno.dispose();
  }
}

class _DenoProcess {
  static final _logger = Logger('YoutubeExplode.Deno.Process');

  final Process _process;
  final StreamController<String> _stdoutController =
      StreamController.broadcast();
  final Directory tmpDir;

  // Queue for incoming eval requests
  final Queue<_EvalRequest> _evalQueue = Queue<_EvalRequest>();
  bool _isProcessing = false; // Flag to indicate if an eval is currently active

  _DenoProcess(this._process, this.tmpDir) {
    // Listen to Deno's stdout and add data to the stream controller
    _process.stdout
        .transform(SystemEncoding().decoder)
        .listen(_stdoutController.add, onDone: () {
      _logger.info('Deno process stdout closed.');
      _stdoutController.close();
    }, onError: (e) {
      _logger.info('Deno process stdout error occurred: $e');
    });
  }

  /// Disposes the Deno process.
  void dispose() {
    _process.kill();
    tmpDir.delete(recursive: true);
  }

  /// Sends JavaScript code to Deno for evaluation.
  /// Assumes single-line input produces single-line output.
  Future<String> eval(String code) {
    final completer = Completer<String>();
    final request = _EvalRequest(code, completer);
    _evalQueue.addLast(request); // Add request to the end of the queue
    _processQueue(); // Attempt to process the queue

    return completer.future;
  }

  // Processes the eval queue.
  void _processQueue() {
    if (_isProcessing || _evalQueue.isEmpty) {
      return; // Already processing or nothing in queue
    }

    _isProcessing = true;
    final request =
        _evalQueue.first; // Get the next request without removing it yet

    StreamSubscription? currentOutputSubscription;
    Completer<void> lineReceived = Completer<void>();

    currentOutputSubscription = _stdoutController.stream.listen((data) {
      if (!lineReceived.isCompleted) {
        // Assuming single line output per eval.
        // This will capture the first full line or chunk received after sending the code.
        request.completer.complete(data.trim());
        lineReceived.complete();
        currentOutputSubscription
            ?.cancel(); // Cancel subscription for this request
        _evalQueue.removeFirst(); // Remove the processed request
        _isProcessing = false; // Mark as no longer processing
        _processQueue(); // Attempt to process next item in queue
      }
    }, onError: (e) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(e);
        lineReceived.completeError(e);
        currentOutputSubscription?.cancel();
        _evalQueue.removeFirst();
        _isProcessing = false;
        _processQueue();
      }
    }, onDone: () {
      if (!request.completer.isCompleted) {
        request.completer.completeError(
            StateError('Deno process closed while awaiting eval result.'));
        lineReceived.completeError(
            StateError('Deno process closed while awaiting eval result.'));
        currentOutputSubscription?.cancel();
        _evalQueue.removeFirst();
        _isProcessing = false;
        _processQueue();
      }
    });

    _process.stdin.writeln(request.code); // Send the code to Deno
  }

  static Future<_DenoProcess> init({
      required String initCode,
      String? denoExe
    }) async {
    final tmpDir = await Directory.systemTemp.createTemp('yt_deno_');
    final tmpFile = File(path.join(tmpDir.path, 'deno_init.js'));
    await tmpFile.writeAsString(initCode);
    final proc = await Process.start(denoExe ?? 'deno', [
      'repl',
      '--quiet',
      '--no-lock',
      '--no-npm',
      '--no-remote',
      '--allow-write=${tmpDir.path}',
      '--eval-file=${tmpFile.path}',
    ], environment: {
      'NO_COLOR': '1',
    });
    _logger.info(
        'Deno process started with PID: ${proc.pid}, using tmpdir: ${tmpDir.path}');
    return _DenoProcess(proc, tmpDir);
  }
}

// Helper class for queue items
class _EvalRequest {
  final String code;
  final Completer<String> completer;

  _EvalRequest(this.code, this.completer);
}
