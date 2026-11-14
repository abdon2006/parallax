import 'package:parallax/data/models/reference_model.dart';
import 'package:parallax/data/models/site_model.dart';

class AnalogsData {
  final Map<String, List<SiteModel>> sites;
  final Map<String, ReferenceModel> references;
  final Map<String, dynamic> settings;

  const AnalogsData({
    required this.sites,
    required this.references,
    required this.settings,
  });

  List<String> get targets => sites.keys.toList(growable: false);

  /// declare the search goal moon or mars ?
  List<SiteModel> sitesFor(String target) => sites[target] ?? const [];

  SiteModel? findSite(int siteId) {
    for (final targetSites in sites.values) {
      for (final site in targetSites) {
        if (site.siteId == siteId) return site;
      }
    }
    return null;
  }

  SiteModel? findSiteIn(String target, int siteId) {
    for (final site in sitesFor(target)) {
      if (site.siteId == siteId) return site;
    }
    return null;
  }

  int? rankIn(String target, int siteId) => findSiteIn(target, siteId)?.rank;

  String? statusIn(String target, int siteId) =>
      findSiteIn(target, siteId)?.status;

  bool isRecommendedInBoth(int siteId) {
    final moon = findSiteIn('Moon', siteId);
    final mars = findSiteIn('Mars', siteId);
    return moon?.status == 'Recommended' && mars?.status == 'Recommended';
  }
}
