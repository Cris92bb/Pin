/// HTML template generator for Google SSO desktop loopback responses.
abstract final class GoogleSsoDesktopHtml {
  /// Builds an HTML response indicating successful OAuth completion.
  static String buildSuccessHtml({String? email, String? name}) {
    final welcome = name != null && name.isNotEmpty
        ? 'Welcome, $name!'
        : 'Sign-in successful!';
    final accountText = email != null && email.isNotEmpty
        ? 'Connected as <strong>$email</strong>'
        : 'Your Google Account is now connected.';

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Pin — Authentication Complete</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0E1411;
      color: #E2E8F0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141A16;
      border: 1px solid #233028;
      border-radius: 20px;
      padding: 40px 32px;
      max-width: 420px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 56px;
      height: 56px;
      background: #162C20;
      border: 1.5px solid #34D399;
      border-radius: 18px;
      font-size: 26px;
      color: #34D399;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      color: #FFFFFF;
      margin-bottom: 10px;
    }
    p {
      font-size: 14px;
      color: #8C9C93;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    strong {
      color: #A7F3D0;
    }
    .hint {
      font-size: 12px;
      color: #556B5D;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">✓</div>
    <h1>$welcome</h1>
    <p>$accountText<br>Return to Pin to finish connecting your board.</p>
    <a href="pin://auth" style="display:inline-block;padding:12px 24px;background:#34D399;color:#0E1411;font-weight:700;border-radius:12px;text-decoration:none;margin-bottom:16px;font-size:14px;">Open Pin</a>
    <div class="hint">This tab may be closed safely.</div>
  </div>
  <script>
    setTimeout(function() {
      try { window.location.href = "pin://auth"; } catch(e) {}
      setTimeout(function() {
        try { window.location.href = "intent://auth#Intent;scheme=pin;package=com.example.pin;end"; } catch(e) {}
      }, 250);
      try { window.close(); } catch(e) {}
    }, 400);
  </script>
</body>
</html>''';
  }

  /// Builds an HTML response indicating the user cancelled Google sign-in.
  static String buildCancelledHtml() {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Pin — Sign-In Cancelled</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0E1411;
      color: #E2E8F0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141A16;
      border: 1px solid #233028;
      border-radius: 20px;
      padding: 40px 32px;
      max-width: 420px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 56px;
      height: 56px;
      background: #2A1F1D;
      border: 1.5px solid #F87171;
      border-radius: 18px;
      font-size: 26px;
      color: #F87171;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      color: #FFFFFF;
      margin-bottom: 10px;
    }
    p {
      font-size: 14px;
      color: #8C9C93;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .hint {
      font-size: 12px;
      color: #556B5D;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">✕</div>
    <h1>Sign-In Cancelled</h1>
    <p>You cancelled Google authentication.<br>You can return to Pin to try again.</p>
    <div class="hint">This tab may be closed safely.</div>
  </div>
</body>
</html>''';
  }

  /// Builds an HTML response presenting an authentication error.
  static String buildErrorHtml(String errorMessage) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Pin — Authentication Error</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0E1411;
      color: #E2E8F0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141A16;
      border: 1px solid #3E2424;
      border-radius: 20px;
      padding: 40px 32px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.6);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 56px;
      height: 56px;
      background: #2A1717;
      border: 1.5px solid #EF4444;
      border-radius: 18px;
      font-size: 26px;
      color: #EF4444;
      margin-bottom: 20px;
    }
    h1 {
      font-size: 22px;
      font-weight: 800;
      color: #FFFFFF;
      margin-bottom: 10px;
    }
    p {
      font-size: 14px;
      color: #F87171;
      line-height: 1.6;
      margin-bottom: 24px;
      word-break: break-word;
    }
    .hint {
      font-size: 12px;
      color: #556B5D;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">!</div>
    <h1>Authentication Error</h1>
    <p>$errorMessage</p>
    <div class="hint">You can close this tab and return to Pin.</div>
  </div>
</body>
</html>''';
  }
}
