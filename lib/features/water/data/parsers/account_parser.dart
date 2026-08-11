import 'package:consumo_plus/features/water/data/parsers/portal_text_parser.dart';
import 'package:consumo_plus/features/water/data/parsers/session_page_parser.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:html/dom.dart' show Document, Element;
import 'package:html/parser.dart' as html_parser;

class AccountParser {
  const AccountParser();

  static const _customerCodeLabels = {
    'CODIGO CLIENTE',
    'CODIGO DE CLIENTE',
    'CODIGO DEL CLIENTE',
    'COD CLIENTE',
  };
  static const _ownerLabels = {
    'PROPIETARIO',
    'TITULAR',
    'NOMBRE DEL PROPIETARIO',
  };
  static const _addressLabels = {'DIRECCION', 'DIRECCION DEL PREDIO'};
  static const _statusLabels = {
    'ESTADO',
    'SERVICIO',
    'ESTADO SERVICIO',
    'ESTADO DEL SERVICIO',
  };
  static const _tariffLabels = {'TARIFA', 'CATEGORIA', 'CATEGORIA TARIFARIA'};
  static const _meterLabels = {
    'MEDIDOR',
    'N MEDIDOR',
    'NRO MEDIDOR',
    'NUMERO MEDIDOR',
    'NUMERO DE MEDIDOR',
  };
  static const _connectionLabels = {
    'TIPO CONEXION',
    'TIPO DE CONEXION',
    'CONEXION',
  };

  WaterAccount parse(
    String source, {
    required String providerId,
    required String customerCode,
    required DateTime synchronizedAt,
  }) {
    if (SessionPageParser.hasLoginForm(source)) {
      throw const SessionExpiredException();
    }
    if (!SessionPageParser.isAuthenticated(source)) {
      throw const UnexpectedPortalStructureException();
    }

    final document = html_parser.parse(source);
    final ownerElement =
        document.querySelector('.user-panel a.d-block') ??
        document.querySelector('.user-panel a') ??
        document.querySelector('aside a.d-block');
    final ownerName = PortalTextParser.normalize(ownerElement?.text ?? '');
    if (ownerName.isEmpty) throw const UnexpectedPortalStructureException();

    return WaterAccount(
      providerId: providerId,
      customerCode: customerCode,
      ownerName: ownerName,
      synchronizedAt: synchronizedAt,
    );
  }

  WaterAccount withSupplyDetails(
    String source, {
    required WaterAccount account,
  }) {
    if (SessionPageParser.hasLoginForm(source)) {
      throw const SessionExpiredException();
    }

    final document = html_parser.parse(source);
    if (!_isBillingPage(document)) {
      throw const UnexpectedPortalStructureException();
    }
    final values = _LabeledValueReader(document);
    return WaterAccount(
      providerId: account.providerId,
      customerCode: values.read(_customerCodeLabels) ?? account.customerCode,
      ownerName: values.read(_ownerLabels) ?? account.ownerName,
      synchronizedAt: account.synchronizedAt,
      serviceAddress: values.read(_addressLabels),
      serviceStatus: values.read(_statusLabels),
      tariffName: values.read(_tariffLabels),
      meterNumber: values.read(_meterLabels),
      connectionType: values.read(_connectionLabels),
    );
  }

  static bool _isBillingPage(Document document) {
    final table =
        document.querySelector('table#example1') ??
        document.querySelector('table');
    if (table == null) return false;
    final headers = table
        .querySelectorAll('thead th, thead td')
        .map((cell) => PortalTextParser.key(cell.text));
    return headers.any((header) => header == 'PERIODO') &&
        headers.any((header) => header.contains('RECIBO'));
  }
}

class _LabeledValueReader {
  _LabeledValueReader(this.document);

  static const _candidateSelector =
      'label, strong, b, span, td, th, div, p, dt, dd, h1, h2, h3, h4, h5, h6';
  static const _allLabels = {
    ...AccountParser._customerCodeLabels,
    ...AccountParser._ownerLabels,
    ...AccountParser._addressLabels,
    ...AccountParser._statusLabels,
    ...AccountParser._tariffLabels,
    ...AccountParser._meterLabels,
    ...AccountParser._connectionLabels,
  };

  final Document document;

  String? read(Set<String> labels) {
    for (final element in document.querySelectorAll(_candidateSelector)) {
      if (element.children.isNotEmpty || _isInsideBillingTable(element)) {
        continue;
      }

      final text = PortalTextParser.normalize(element.text);
      final inline = _inlineValue(text, labels);
      if (inline != null) return inline;
      if (!labels.contains(PortalTextParser.key(text))) continue;

      final sibling = element.nextElementSibling;
      final siblingValue = sibling == null ? null : _elementValue(sibling);
      if (siblingValue != null && !_isKnownLabel(siblingValue)) {
        return siblingValue;
      }

      final parent = element.parent;
      if (parent is Element) {
        final parentText = PortalTextParser.normalize(parent.text);
        if (parentText.startsWith(text)) {
          final remainder = PortalTextParser.normalize(
            parentText
                .substring(text.length)
                .replaceFirst(RegExp(r'^\s*:\s*'), ''),
          );
          if (remainder.isNotEmpty && !_isKnownLabel(remainder)) {
            return remainder;
          }
        }
      }
    }
    return null;
  }

  static String? _inlineValue(String text, Set<String> labels) {
    final separator = text.indexOf(':');
    if (separator < 0) return null;
    final label = PortalTextParser.key(text.substring(0, separator));
    if (!labels.contains(label)) return null;
    final value = PortalTextParser.normalize(text.substring(separator + 1));
    return value.isEmpty ? null : value;
  }

  static String? _elementValue(Element element) {
    final value = PortalTextParser.normalize(
      element.attributes['value'] ?? element.text,
    );
    return value.isEmpty ? null : value;
  }

  static bool _isKnownLabel(String value) {
    return _allLabels.contains(PortalTextParser.key(value));
  }

  static bool _isInsideBillingTable(Element element) {
    for (
      Element? current = element;
      current != null;
      current = current.parent
    ) {
      if (current.localName == 'table' && current.id == 'example1') return true;
    }
    return false;
  }
}
