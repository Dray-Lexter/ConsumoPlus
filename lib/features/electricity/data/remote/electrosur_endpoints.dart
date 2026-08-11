abstract final class ElectrosurEndpoints {
  static final base = Uri.parse('http://www.electrosur.com.pe:81/');
  static final login = base.resolve('Login');
  static final accountStatus = base.resolve('EstadoCuenta');
  static final consumptions = base.resolve('Consumos');
  static final payments = base.resolve('Pagos');
  static final supply = base.resolve('Suministro');

  static bool isAllowed(Uri uri) {
    return uri.scheme == 'http' &&
        uri.host == 'www.electrosur.com.pe' &&
        uri.port == 81;
  }
}
