/*
 * Copyright (C) 2022 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:packagekit/packagekit.dart';
import 'package:provider/provider.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/services/package_service.dart';
import 'package:software/store_app/common/app_data.dart';
import 'package:software/store_app/common/app_icon.dart';
import 'package:software/store_app/common/app_page/app_loading_page.dart';
import 'package:software/store_app/common/app_page/app_page.dart';
import 'package:software/store_app/common/packagekit/package_controls.dart';
import 'package:software/store_app/common/packagekit/package_model.dart';
import 'package:ubuntu_service/ubuntu_service.dart';

class PackagePage extends StatefulWidget {
  const PackagePage({
    super.key,
    required this.noUpdate,
    required this.id,
    required this.installedId,
  });

  final bool noUpdate;
  final PackageKitPackageId id;
  final PackageKitPackageId installedId;

  static Widget create({
    required BuildContext context,
    required PackageKitPackageId id,
    required PackageKitPackageId installedId,
    bool noUpdate = true,
  }) {
    return ChangeNotifierProvider(
      create: (context) =>
          PackageModel(service: getService<PackageService>(), packageId: id),
      child: PackagePage(
        noUpdate: noUpdate,
        id: id,
        installedId: installedId,
      ),
    );
  }

  static Future<void> push(BuildContext context, PackageKitPackageId id) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PackagePage.create(
            context: context,
            id: id,
            installedId: id,
          );
        },
      ),
    );
  }

  @override
  State<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> {
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<PackageModel>()
          .init(update: !widget.noUpdate)
          .then((value) => initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PackageModel>();

    final appData = AppData(
      confinementName: context.l10n.classic,
      license: model.license,
      strict: false,
      verified: false,
      starredDeveloper: false,
      publisherName: context.l10n.website,
      website: model.url,
      summary: model.summary,
      title: widget.id.name,
      name: widget.id.name,
      version: widget.id.version,
      screenShotUrls: model.screenshotUrls,
      description: model.description,
      userReviews: model.userReviews,
      averageRating: model.averageRating,
    );
    return !initialized
        ? const AppLoadingPage()
        : AppPage(
            appData: appData,
            permissionContainer: null,
            icon: AppIcon(
              iconUrl: model.iconUrl,
              size: 150,
            ),
            controls: PackageControls(
              isInstalled: model.isInstalled,
              packageState: model.packageState,
              remove: () => model.remove(),
              install: () => model.install(),
            ),
            onReviewSend: model.sendReview,
            onRatingUpdate: (v) => model.reviewRating = v,
            onReviewTitleChanged: (v) => model.reviewTitle = v,
            onReviewUserChanged: (v) => model.reviewUser = v,
            onReviewChanged: (v) => model.review = v,
            reviewRating: model.reviewRating,
            review: model.review,
            reviewTitle: model.reviewTitle,
            reviewUser: model.reviewUser,
          );
  }
}
