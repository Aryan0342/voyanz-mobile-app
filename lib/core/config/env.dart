enum Environment { dev, staging, prod }

class EnvConfig {
  final Environment environment;
  final String baseUrl;
  final String? apiKey;

  const EnvConfig({
    required this.environment,
    required this.baseUrl,
    this.apiKey,
  });

  /// TODO: Replace placeholder URLs when Visioco provides them.
  static const dev = EnvConfig(
    environment: Environment.dev,
    baseUrl: 'https://dev.visioco.co',
  );

  static const staging = EnvConfig(
    environment: Environment.staging,
    baseUrl: 'https://staging.visioco.co',
  );

  static const prod = EnvConfig(
    environment: Environment.prod,
    baseUrl: 'https://voyanz.visioco.co',
  );

  static EnvConfig current = dev;
}
