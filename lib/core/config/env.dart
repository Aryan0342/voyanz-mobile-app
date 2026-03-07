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

  static const dev = EnvConfig(
    environment: Environment.dev,
    baseUrl: 'https://voyanz.com',
    apiKey: '7645ED1A-235F-459E-8E63-8178078927A3',
  );

  static const staging = EnvConfig(
    environment: Environment.staging,
    baseUrl: 'https://voyanz.com',
    apiKey: '7645ED1A-235F-459E-8E63-8178078927A3',
  );

  static const prod = EnvConfig(
    environment: Environment.prod,
    baseUrl: 'https://voyanz.com',
    apiKey: '7645ED1A-235F-459E-8E63-8178078927A3',
  );

  static EnvConfig current = prod;
}
