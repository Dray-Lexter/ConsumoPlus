abstract final class EpsTacnaEndpoints {
  static final base = Uri.parse('http://oficinavirtual.epstacna.com.pe/');
  static final loginPage = base.resolve('src/vista/v_login.php');
  static final login = base.resolve('src/controlador/login.php');
  static final main = base.resolve('src/controlador/main.php');
  static final billing = base.resolve('src/controlador/ctacte.php');
  static final payments = base.resolve('src/controlador/historialpagos.php');
  static final logout = base.resolve('src/controlador/salir.php');

  static bool isAllowed(Uri uri) {
    return uri.scheme == 'http' &&
        uri.host == base.host &&
        (uri.hasPort ? uri.port == 80 : true) &&
        uri.userInfo.isEmpty;
  }
}
