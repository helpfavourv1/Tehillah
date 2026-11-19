import 'package:tehillah/core/models/json_util.dart';

/// One entry on the licenses screen: a scripture source, a font or an icon set.
final class LicenseNotice {
  const LicenseNotice({
    required this.id,
    required this.title,
    required this.license,
    required this.attribution,
    this.link,
  });

  factory LicenseNotice.fromJson(Map<String, Object?> json) {
    final Object? link = json['link'];
    if (link != null && (link is! String || !link.startsWith('https://'))) {
      throw const FormatException('"link" must be an https URL or null');
    }
    return LicenseNotice(
      id: readString(json, 'id'),
      title: readString(json, 'title'),
      license: readString(json, 'license'),
      attribution: readString(json, 'attribution'),
      link: link as String?,
    );
  }

  final String id;

  /// What the notice is for, for example the translation name.
  final String title;

  /// The license name, for example `CC BY 4.0`.
  final String license;

  /// The exact credit or copyright text the license requires.
  final String attribution;

  /// Where the license or source can be read, or null.
  final String? link;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'license': license,
        'attribution': attribution,
        'link': link,
      };

  @override
  bool operator ==(Object other) =>
      other is LicenseNotice &&
      other.id == id &&
      other.title == title &&
      other.license == license &&
      other.attribution == attribution &&
      other.link == link;

  @override
  int get hashCode => Object.hash(id, title, license, attribution, link);
}
