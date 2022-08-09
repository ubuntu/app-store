import 'package:flutter/material.dart';
import 'package:packagekit/packagekit.dart';
import 'package:provider/provider.dart';
import 'package:software/store_app/common/constants.dart';
import 'package:software/store_app/my_apps/my_packages_model.dart';
import 'package:software/store_app/common/package_dialog.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class MyPackagesPage extends StatefulWidget {
  const MyPackagesPage({Key? key}) : super(key: key);

  static Widget create(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyPackagesModel(getService<PackageKitClient>()),
      child: const MyPackagesPage(),
    );
  }

  @override
  State<MyPackagesPage> createState() => _MyPackagesPageState();
}

class _MyPackagesPageState extends State<MyPackagesPage> {
  @override
  void initState() {
    context.read<MyPackagesModel>().init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MyPackagesModel>();
    return model.packages.isNotEmpty
        ? GridView.builder(
            padding: const EdgeInsets.all(20.0),
            gridDelegate: kGridDelegate,
            shrinkWrap: true,
            itemCount: model.packages.length,
            itemBuilder: (context, index) {
              final package = model.packages[index];
              return YaruBanner(
                name: package.name,
                summary: package.version,
                fallbackIconData: YaruIcons.package_deb,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) =>
                      PackageDialog.create(context: context, id: package),
                ),
              );
            },
          )
        : const SizedBox();
  }
}
