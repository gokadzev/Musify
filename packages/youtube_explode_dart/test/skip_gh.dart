import 'dart:io';

/// Utility to skip a test if running inside GitHub Actions, since YT consistently blocks requests running from that environment.
final skipGH = Platform.environment.containsKey('GITHUB_ACTIONS')
    ? 'Always fails in GitHub Actions'
    : null;
