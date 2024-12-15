import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<SendPhoneNumberVerification>(_onSendPhoneNumberVerification);
    on<VerifyOTP>(_onVerifyOTP);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<SignOut>(_onSignOut);
    on<LoadUserFromStorage>(_onLoadUserFromStorage); // New Event
  }

  Future<void> _onSendPhoneNumberVerification(
    SendPhoneNumberVerification event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      // Simulate phone number verification process
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(
        isLoading: false,
        phoneNumber: event.phoneNumber,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onVerifyOTP(
    VerifyOTP event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      // Simulate OTP verification process
      await Future.delayed(const Duration(seconds: 2));

      // Generate a mock `userId` (Replace with real logic)
      final userId = 'USER_${DateTime.now().millisecondsSinceEpoch}';

      // Save userId locally
      await _saveUserIdToStorage(userId);

      emit(state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userId: userId,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      // Simulate profile update process
      await Future.delayed(const Duration(seconds: 1));

      emit(state.copyWith(
        isLoading: false,
        userCategory: event.userCategory,
        residenceType: event.residenceType,
        isAuthenticated: true,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSignOut(
    SignOut event,
    Emitter<AuthState> emit,
  ) async {
    // Clear local storage
    await _clearUserIdFromStorage();
    emit(const AuthState());
  }

  Future<void> _onLoadUserFromStorage(
    LoadUserFromStorage event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      final userId = await _getUserIdFromStorage();

      if (userId != null) {
        emit(state.copyWith(
          isAuthenticated: true,
          userId: userId,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Helper methods to interact with SharedPreferences

  Future<void> _saveUserIdToStorage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  Future<String?> _getUserIdFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> _clearUserIdFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
}
