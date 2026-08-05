import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/data/enums.dart';
import 'package:nestly/state/vault_ui.dart';

void main() {
  test('back exits select then folder then allows route pop', () {
    final ctrl = VaultUiController();
    expect(ctrl.state.canPopRoute, isTrue);

    ctrl.setCategory(VaultFolder.health.label);
    expect(ctrl.state.canPopRoute, isFalse);
    expect(ctrl.handleBack(), isTrue);
    expect(ctrl.state.category, VaultFolder.allLabel);
    expect(ctrl.state.canPopRoute, isTrue);

    ctrl.startSelecting(seedId: 'a');
    expect(ctrl.state.selecting, isTrue);
    expect(ctrl.state.selectedIds, {'a'});
    expect(ctrl.handleBack(), isTrue);
    expect(ctrl.state.selecting, isFalse);
    expect(ctrl.state.selectedIds, isEmpty);
    expect(ctrl.handleBack(), isFalse);
  });

  test('toggle selected and query updates', () {
    final ctrl = VaultUiController(initialCategory: VaultFolder.family.label);
    expect(ctrl.state.category, VaultFolder.family.label);
    ctrl.setQuery('passport');
    ctrl.toggleSelected('1');
    ctrl.toggleSelected('2');
    ctrl.toggleSelected('1');
    expect(ctrl.state.query, 'passport');
    expect(ctrl.state.selectedIds, {'2'});
  });
}
