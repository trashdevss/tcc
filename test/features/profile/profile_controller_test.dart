import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tcc_3/common/data/data_result.dart';
import 'package:tcc_3/common/data/exceptions.dart';
import 'package:tcc_3/common/models/user_model.dart';
import 'package:tcc_3/features/profile/profile_controller.dart';
import 'package:tcc_3/features/profile/profile_state.dart';

import '../../mock/mock_classes.dart';

void main() {
  late ProfileController sut;
  late MockUserDataService userDataService;

  setUp(() {
    userDataService = MockUserDataService();
    sut = ProfileController(userDataService: userDataService);
  });

  group('Tests ProfileController State', () {
    test('Initial state should be ProfileInitialState', () {
      expect(sut.state, isA<ProfileStateInitial>());
    });

    test(
        'When getUserData is called and return success, state should be ProfileStateSuccess',
        () async {
      when(() => userDataService.getUserData()).thenAnswer(
        (_) async => DataResult.success(
          UserModel(
            email: 'user@email.com',
            name: 'User',
            id: '123',
          ),
        ),
      );

      await sut.getUserData();

      expect(sut.state, isA<ProfileStateSuccess>());
      expect((sut.state as ProfileStateSuccess).user, isA<UserModel>());
      expect((sut.state as ProfileStateSuccess).user?.email, 'user@email.com');
      expect((sut.state as ProfileStateSuccess).user?.name, 'User');
      expect((sut.state as ProfileStateSuccess).user?.id, '123');
    });

    test(
        'When getUserData is called and return failure, state should be ProfileStateError',
        () async {
      when(() => userDataService.getUserData()).thenAnswer(
        (_) async =>
            DataResult.failure(const UserDataException(code: 'not-found')),
      );

      await sut.getUserData();

      expect(sut.state, isA<ProfileStateError>());
      expect((sut.state as ProfileStateError).message,
          'User data not found. Please login again.');
    });

    test(
        'When updateUserName is called and return success, state should be ProfileStateSuccess',
        () async {
      when(() => userDataService.updateUserName(any()))
          .thenAnswer((_) async => DataResult.success(
                UserModel(
                  id: '123',
                  name: 'User Alterado',
                  email: 'user@email.com',
                ),
              ));

      await sut.updateUserName('User Alterado');

      expect(sut.state, isA<ProfileStateSuccess>());
      expect(sut.showNameUpdateMessage, isTrue);
    });
     test(
        'When updateUserName is called and return failure, state should be ProfileStateError',
        () async {
      when(() => userDataService.updateUserName(any())).thenAnswer(
        (_) async => DataResult.failure(
          const UserDataException(code: 'update-failed'),
        ),
      );

      await sut.updateUserName('Novo Nome');

      expect(sut.state, isA<ProfileStateError>());
      expect((sut.state as ProfileStateError).message,
    'An internal error has ocurred while update user data. Please try again later.');

    });
  });
}
