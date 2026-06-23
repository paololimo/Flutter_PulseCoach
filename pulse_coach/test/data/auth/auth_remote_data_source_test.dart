// [18.0-DS-001..002] AuthRemoteDataSource.deleteAccount() signOut-safety assertions.
// Uses @visibleForTesting hooks — no Supabase initialization required.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/features/auth/data/datasources/auth_remote_data_source.dart';

import 'auth_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClientProvider])
void main() {
  late MockSupabaseClientProvider mockSupabase;
  late AuthRemoteDataSource sut;

  setUp(() {
    mockSupabase = MockSupabaseClientProvider();
    sut = AuthRemoteDataSource(mockSupabase);
  });

  group('deleteAccount — signOut-after-200 safety', () {
    test(
      '18.0-DS-001: non-200 response → throws AND signOut is NOT called',
      () async {
        bool signOutCalled = false;
        sut.invokeDeleteAccount = () async {
          throw Exception('delete_account_cascade failed: server error');
        };
        sut.performSignOut = () async {
          signOutCalled = true;
        };

        await expectLater(
          sut.deleteAccount(),
          throwsA(isA<Exception>()),
        );
        expect(
          signOutCalled,
          isFalse,
          reason: '16.4-D2: signOut must NOT run when server returns non-200',
        );
      },
    );

    test(
      '18.0-DS-002: 200 response → deleteAccount completes AND signOut IS called',
      () async {
        bool signOutCalled = false;
        sut.invokeDeleteAccount = () async => 200;
        sut.performSignOut = () async {
          signOutCalled = true;
        };

        await sut.deleteAccount();

        expect(
          signOutCalled,
          isTrue,
          reason: 'signOut must be called after successful (200) server response',
        );
      },
    );
  });
}
