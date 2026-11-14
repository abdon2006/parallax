import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:parallax/core/constants/app_errors.dart';
import 'package:parallax/data/models/analogs_data.dart';
import 'package:parallax/data/models/reference_model.dart';
import 'package:parallax/data/models/site_model.dart';

class AnalogRepository {
  Future<Either<Failure, AnalogsData>> loadData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/results.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final sites = <String, List<SiteModel>>{};
      final references = <String, ReferenceModel>{};

      final targets = json['targets'] as Map<String, dynamic>;
      for (final entry in targets.entries) {
        final bodyData = entry.value as Map<String, dynamic>;

        references[entry.key] = ReferenceModel.fromJson(
          bodyData['reference_conditions'] as Map<String, dynamic>,
        );

        final sitesList = bodyData['sites'] as List<dynamic>;
        sites[entry.key] =
            sitesList
                .map((site) => SiteModel.fromJson(site as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => a.rank.compareTo(b.rank));
      }

      return Right(
        AnalogsData(
          sites: sites,
          references: references,
          settings: (json['settings'] as Map<String, dynamic>?) ?? const {},
        ),
      );
    } catch (_) {
      return Left(
        FetchDataError(message: 'Could not load the analog dataset.'),
      );
    }
  }
}
