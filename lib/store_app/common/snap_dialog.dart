import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/services/app_change_service.dart';
import 'package:software/store_app/common/constants.dart';
import 'package:software/store_app/common/snap_channel_expandable.dart';
import 'package:software/store_app/common/snap_connections_settings.dart';
import 'package:software/store_app/common/snap_content.dart';
import 'package:software/store_app/common/snap_installation_controls.dart';
import 'package:software/store_app/common/snap_model.dart';
import 'package:software/store_app/common/snap_page_header.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class SnapDialog extends StatefulWidget {
  const SnapDialog({
    Key? key,
  }) : super(key: key);

  static Widget create({
    required BuildContext context,
    required String huskSnapName,
  }) =>
      ChangeNotifierProvider<SnapModel>(
        create: (_) => SnapModel(
          doneString: context.l10n.done,
          getService<SnapdClient>(),
          getService<AppChangeService>(),
          huskSnapName: huskSnapName,
        ),
        child: const SnapDialog(),
      );

  @override
  State<SnapDialog> createState() => _SnapDialogState();
}

class _SnapDialogState extends State<SnapDialog> {
  @override
  void initState() {
    context.read<SnapModel>().init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SnapModel>();
    if (model.name != null) {
      return AlertDialog(
        scrollable: true,
        actionsAlignment: MainAxisAlignment.spaceBetween,
        contentPadding: const EdgeInsets.only(
          left: 25,
          right: 25,
        ),
        titlePadding: EdgeInsets.zero,
        title: const SizedBox(
          width: dialogWidth,
          child: YaruDialogTitle(
            mainAxisAlignment: MainAxisAlignment.center,
            closeIconData: YaruIcons.window_close,
            titleWidget: SnapPageHeader(),
          ),
        ),
        content: model.connectionsExpanded && model.connections.isNotEmpty
            ? SnapConnectionsSettings(connections: model.connections)
            : const SizedBox(width: dialogWidth, child: SnapContent()),
        actions: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: SizedBox(child: SnapChannelExpandable()),
          ),
          if (model.appChangeInProgress)
            const SizedBox(
              height: 25,
              child: YaruCircularProgressIndicator(
                strokeWidth: 3,
              ),
            )
          else
            const SnapInstallationControls()
        ],
      );
    } else {
      return const AlertDialog(
        content: SizedBox(
          height: 200,
          child: Center(child: YaruCircularProgressIndicator()),
        ),
      );
    }
  }
}
