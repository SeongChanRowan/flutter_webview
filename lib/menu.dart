import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';

const String kExamplePage = '''
<!DOCTYPE html>
<html lang="en">
<head>
<title>Load file or HTML string example</title>
</head>
<body>

<h1>Local demo page</h1>
<p>
 This is an example page used to demonstrate how to load a local file or HTML
 string using the <a href="https://pub.dev/packages/webview_flutter">Flutter
 webview</a> plugin.
</p>

</body>
</html>
''';

enum _MenuOptions {
  navigateDelegate,
  userAgent,
  javascriptChannel,
  listCookies,
  clearCookies,
  addCookie,
  setCookie,
  removeCookie,
  loadFlutterAsset,
  loadLocalFile,
  loadHtmlString,
}

class Menu extends StatefulWidget {
  const Menu({required this.controller, super.key});

  final WebViewController controller;

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  final WebViewCookieManager cookieManager = WebViewCookieManager();

  // List Cookies
  Future<void> _onListCookies(WebViewController controller) async {
    final String cookies = await controller.runJavaScriptReturningResult('''
        (document.cookie.length === 0) ? '' : document.cookie
      ''') as String;

    if (!mounted) return;

    print(
        'Cookie value: [$cookies], Length: ${cookies.length}, isEmpty: ${cookies.isEmpty}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cookies == '""'
            ? 'There are no cookies'
            : cookies.replaceAll('"', '')),
      ),
    );
  }

  // Clear Cookies
  Future<void> _onClearCookies() async {
    final hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, thery are gone!';

    if (!hadCookies) {
      message = 'There were no cookies to clear.';
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // Add Cookie
  Future<void> _onAddCookie(WebViewController controller) async {
    // 30일 후 만료되는 쿠키 설정
    await controller.runJavaScript('''
      var date = new Date();
      date.setTime(date.getTime()+(30*24*60*60*1000));
      document.cookie = "FirstName=Caleb; expires=" + date.toGMTString();
    ''');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom cookie added.'),
      ),
    );
  }

  // Set Cookie
  Future<void> _onSetCookie(WebViewController controller) async {
    // 현재 URL의 도메인 가져오기
    final url = await controller.currentUrl();
    final domain = Uri.parse(url ?? '').host;

    await cookieManager.setCookie(
      WebViewCookie(
        name: 'foo',
        value: 'bar',
        domain: domain, // 현재 도메인 사용
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom cookie is set.'),
      ),
    );
  }

  // Remove Cookies
  Future<void> _onRemoveCookie(WebViewController controller) async {
    await controller.runJavaScript(
        'document.cookie="FirstName=Caleb; expires=Thu, 01 Jan 1970 00:00:00 UTC" ');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom cookie removed.'),
      ),
    );
  }

  // Load Flutter Asset
  Future<void> _onLoadFlutterAssetExample(
      WebViewController controller, BuildContext context) async {
    await controller.loadFlutterAsset('assets/www/index.html');
  }

  // Load Local File
  Future<void> _onLoadLocalFileExample(
      WebViewController controller, BuildContext context) async {
    final String pathToIndex = await _prepareLocalFile();

    await controller.loadFile(pathToIndex);
  }

  static Future<String> _prepareLocalFile() async {
    final String tmpDir = (await getTemporaryDirectory()).path;
    final File indexFile = File('$tmpDir/www/index.html');

    await Directory('$tmpDir/www').create(recursive: true);
    await indexFile.writeAsString(kExamplePage);

    return indexFile.path;
  }

  //Load HTML String
  Future<void> _onLoadHtmlStringExample(
      WebViewController controller, BuildContext context) async {
    await controller.loadHtmlString(kExamplePage);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuOptions>(
      onSelected: (value) async {
        switch (value) {
          case _MenuOptions.navigateDelegate:
            await widget.controller
                .loadRequest(Uri.parse('https://youtube.com'));

          case _MenuOptions.userAgent:
            final userAgent = await widget.controller
                .runJavaScriptReturningResult('navigator.userAgent');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$userAgent'),
            ));

          case _MenuOptions.javascriptChannel:
            await widget.controller.runJavaScript('''
              var req = new XMLHttpRequest();
              req.open('GET', "https://api64.ipify.org/?format=json");
              req.onload = function() {
                if (req.status == 200) {
                  let response = JSON.parse(req.responseText);
                  SnackBar.postMessage("IP Address: " + response.ip);
                } else {
                  SnackBar.postMessage("Error: " + req.status);
                }
              }
              req.send();''');

          case _MenuOptions.clearCookies:
            await _onClearCookies();
          case _MenuOptions.listCookies:
            await _onListCookies(widget.controller);
          case _MenuOptions.addCookie:
            await _onAddCookie(widget.controller);
          case _MenuOptions.setCookie:
            await _onSetCookie(widget.controller);
          case _MenuOptions.removeCookie:
            await _onRemoveCookie(widget.controller);
          case _MenuOptions.loadFlutterAsset:
            if (!mounted) return;
            await _onLoadFlutterAssetExample(widget.controller, context);
          case _MenuOptions.loadLocalFile:
            if (!mounted) return;
            await _onLoadLocalFileExample(widget.controller, context);
          case _MenuOptions.loadHtmlString:
            if (!mounted) return;
            await _onLoadHtmlStringExample(widget.controller, context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.navigateDelegate,
          child: Text('Navigate to Youtube'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.userAgent,
          child: Text('Show user-agent'),
        ),
        const PopupMenuItem(
          value: _MenuOptions.javascriptChannel,
          child: Text('Lookup IP Address'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.clearCookies,
          child: Text('Clear cookies'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.listCookies,
          child: Text('List cookies'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.addCookie,
          child: Text('Add cookie'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.setCookie,
          child: Text('Set cookie'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.removeCookie,
          child: Text('Remove cookie'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.loadFlutterAsset,
          child: Text('Load Flutter Asset'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.loadHtmlString,
          child: Text('Load HTML string'),
        ),
        const PopupMenuItem<_MenuOptions>(
          value: _MenuOptions.loadLocalFile,
          child: Text('Load local file'),
        ),
      ],
    );
  }
}
