import 'package:flutter/material.dart';
import 'package:tcc_3/services/sync_services/sync_controller.dart';
import 'package:tcc_3/services/sync_services/sync_state.dart';

import '../../common/constants/constants.dart';
import '../../common/extensions/extensions.dart';
import '../../common/widgets/widgets.dart';

import '../../locator.dart';
import 'splash_controller.dart';
import 'splash_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with CustomModalSheetMixin {
  final _splashController = locator.get<SplashController>();
  final _syncController = locator.get<SyncController>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => Sizes.init(context));

    _splashController.isUserLogged();
    _splashController.addListener(_handleSplashStateChange);
    _syncController.addListener(_handleSyncStateChange);
  }

  @override
  void dispose() {
    _splashController.dispose();
    _syncController.dispose();
    super.dispose();
  }

  void _handleSplashStateChange() {
    if (_splashController.state is AuthenticatedUser) {
      _syncController.syncFromServer();
    } else {
      Navigator.pushReplacementNamed(
        context,
        NamedRoute.initial,
      );
    }
  }

  void _handleSyncStateChange() {
    final state = _syncController.state;

    switch (state.runtimeType) {
      case DownloadedDataFromServer:
        _syncController.syncToServer();
        break;
      case UploadedDataToServer:
        Navigator.pushReplacementNamed(
          context,
          NamedRoute.home,
        );
        break;
      case SyncStateError:
      case UploadDataToServerError:
      case DownloadDataFromServerError:
        showCustomModalBottomSheet(
          context: context,
          content: (state as SyncStateError).message,
          buttonText: 'Go to login',
          isDismissible: false,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.signIn,
            ModalRoute.withName(NamedRoute.initial),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.greenGradient,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'financy',
              style: AppTextStyles.bigText50.copyWith(color: AppColors.white),
            ),
            Text(
              'Syncing data...',
              style: AppTextStyles.smallText13.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 16.0),
            const CustomCircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}