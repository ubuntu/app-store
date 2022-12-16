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
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:software/app/common/app_icon.dart';
import 'package:software/app/common/constants.dart';
import 'package:software/app/common/packagekit/package_page.dart';
import 'package:software/app/common/snap/snap_page.dart';
import 'package:software/app/explore/explore_model.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/services/appstream/appstream_utils.dart'
    as appstream_icons;
import 'package:software/snapx.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.appFinding,
    required this.showSnap,
    required this.showPackageKit,
  });

  final MapEntry<String, AppFinding> appFinding;
  final bool showSnap;
  final bool showPackageKit;

  @override
  Widget build(BuildContext context) {
    var onTap = appFinding.value.snap != null &&
            appFinding.value.appstream != null &&
            showSnap &&
            showPackageKit
        ? () => SnapPage.push(
              context: context,
              snap: appFinding.value.snap!,
              appstream: appFinding.value.appstream,
            )
        : () {
            if (appFinding.value.appstream != null && showPackageKit) {
              PackagePage.push(
                context,
                appstream: appFinding.value.appstream!,
              );
            }
            if (appFinding.value.snap != null && showSnap) {
              SnapPage.push(
                context: context,
                snap: appFinding.value.snap!,
              );
            }
          };
    var iconUrl =
        appFinding.value.snap?.iconUrl ?? appFinding.value.appstream?.icon;
    var title = appFinding.key;

    var subtitle = SearchBannerSubtitle(
      appFinding: appFinding.value,
      showSnap: showSnap,
      showPackageKit: showPackageKit,
    );

    var appIcon = Padding(
      padding: const EdgeInsets.only(bottom: 55, right: 5),
      child: AppIcon(
        iconUrl: iconUrl,
      ),
    );

    return YaruBanner.tile(
      padding: const EdgeInsets.only(
        left: kYaruPagePadding,
        right: kYaruPagePadding,
      ),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle,
      icon: appIcon,
      onTap: onTap,
    );
  }
}

class SearchBannerSubtitle extends StatelessWidget {
  const SearchBannerSubtitle({
    super.key,
    required this.appFinding,
    this.showSnap = true,
    this.showPackageKit = true,
  });

  final AppFinding appFinding;
  final bool showSnap, showPackageKit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;

    var publisherName = context.l10n.unknown;

    if (appFinding.snap != null &&
        appFinding.snap!.publisher != null &&
        showSnap) {
      publisherName = appFinding.snap!.publisher!.displayName;
    }

    if (appFinding.appstream != null && showPackageKit) {
      if (appFinding.appstream!
              .developerName[Localizations.localeOf(context).toLanguageTag()] !=
          null) {
        publisherName = appFinding.appstream!
            .developerName[Localizations.localeOf(context).toLanguageTag()]!;
      } else if (appFinding.appstream!.urls.isNotEmpty) {
        publisherName = appFinding.appstream!.urls.first.url;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              publisherName,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            if (appFinding.snap?.verified == true)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Icon(
                  Icons.verified,
                  color: light ? kGreenLight : kGreenDark,
                  size: 12,
                ),
              )
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          appFinding.snap?.summary ??
              appFinding.appstream?.localizedSummary() ??
              '',
          overflow: TextOverflow.ellipsis,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RatingBar.builder(
                initialRating: appFinding.rating ?? 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: EdgeInsets.zero,
                itemSize: 20,
                itemBuilder: (context, _) => const Icon(
                  YaruIcons.star_filled,
                  color: kRatingOrange,
                ),
                onRatingUpdate: (rating) {},
                ignoreGestures: true,
              ),
              PackageIndicator(
                appFinding: appFinding,
                showSnap: showSnap,
                showPackageKit: showPackageKit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PackageIndicator extends StatelessWidget {
  const PackageIndicator({
    super.key,
    required this.appFinding,
    this.showSnap = true,
    this.showPackageKit = true,
  });

  final AppFinding appFinding;
  final bool showSnap;
  final bool showPackageKit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (appFinding.snap != null && showSnap)
          const Icon(
            YaruIcons.snapcraft,
            color: kSnapcraftColor,
            size: 20,
          ),
        if (appFinding.appstream != null && showPackageKit)
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Icon(
              YaruIcons.debian,
              color: kDebianColor,
              size: 20,
            ),
          )
      ],
    );
  }
}
