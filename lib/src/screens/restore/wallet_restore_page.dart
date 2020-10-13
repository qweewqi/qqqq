import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/view_model/wallet_restore_view_model.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_from_keys_form.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_from_seed_form.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';

class WalletRestorePage extends BasePage {
  WalletRestorePage(this.walletRestoreViewModel)
      : walletRestoreFromSeedFormKey =
            GlobalKey<WalletRestoreFromSeedFormState>(),
        walletRestoreFromKeysFormKey =
            GlobalKey<WalletRestoreFromKeysFromState>(),
        _pages = [],
        _controller = PageController(initialPage: 0) {
    _pages.addAll([
      WalletRestoreFromSeedForm(key: walletRestoreFromSeedFormKey),
      WalletRestoreFromKeysFrom(key: walletRestoreFromKeysFormKey)
    ]);
  }

  @override
  Widget middle(BuildContext context) => Observer(
      builder: (_) => Text(
            walletRestoreViewModel.mode == WalletRestoreMode.seed
                ? S.current.restore_title_from_seed
                : S.current.restore_title_from_keys,
            style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: titleColor ??
                    Theme.of(context).primaryTextTheme.title.color),
          ));

  @override
  String get title => S.current.restore_title_from_seed;

  final WalletRestoreViewModel walletRestoreViewModel;
  final PageController _controller;
  final List<Widget> _pages;
  final GlobalKey<WalletRestoreFromSeedFormState> walletRestoreFromSeedFormKey;
  final GlobalKey<WalletRestoreFromKeysFromState> walletRestoreFromKeysFormKey;

  @override
  Widget body(BuildContext context) {
    reaction((_) => walletRestoreViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (_) {
                return AlertWithOneAction(
                    alertTitle: S.current.new_wallet,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }
    });

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
          child: PageView.builder(
              onPageChanged: (page) {
                walletRestoreViewModel.mode =
                    page == 0 ? WalletRestoreMode.seed : WalletRestoreMode.keys;
              },
              controller: _controller,
              itemCount: _pages.length,
              itemBuilder: (_, index) => _pages[index])),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: SmoothPageIndicator(
            controller: _controller,
            count: _pages.length,
            effect: ColorTransitionEffect(
                spacing: 6.0,
                radius: 6.0,
                dotWidth: 6.0,
                dotHeight: 6.0,
                dotColor: Theme.of(context).hintColor.withOpacity(0.5),
                activeDotColor: Theme.of(context).hintColor),
          )),
      Padding(
          padding: EdgeInsets.only(top: 20, bottom: 40, left: 25, right: 25),
          child: PrimaryButton(
              text: S.of(context).restore_recover,
              isDisabled: false,
              onPressed: () =>
                  walletRestoreViewModel.create(options: _credentials()),
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white)),
    ]);
  }

  Map<String, dynamic> _credentials() {
    final credentials = <String, dynamic>{};

    if (walletRestoreViewModel.mode == WalletRestoreMode.seed) {
      credentials['seed'] = walletRestoreFromSeedFormKey
          .currentState.seedWidgetStateKey.currentState.text;
      credentials['height'] = walletRestoreFromSeedFormKey
          .currentState.blockchainHeightKey.currentState.height;
    } else {
      credentials['address'] =
          walletRestoreFromKeysFormKey.currentState.addressController.text;
      credentials['viewKey'] =
          walletRestoreFromKeysFormKey.currentState.viewKeyController.text;
      credentials['spendKey'] =
          walletRestoreFromKeysFormKey.currentState.spendKeyController.text;
      credentials['height'] = walletRestoreFromKeysFormKey
          .currentState.blockchainHeightKey.currentState.height;
    }

    return credentials;
  }
}
