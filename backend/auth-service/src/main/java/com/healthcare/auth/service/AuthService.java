package com.healthcare.auth.service;

import com.healthcare.auth.dto.ChangePasswordRequest;
import com.healthcare.auth.dto.ForgotPasswordRequest;
import com.healthcare.auth.dto.LoginRequest;
import com.healthcare.auth.dto.RegisterRequest;
import com.healthcare.auth.dto.ResetPasswordRequest;
import com.healthcare.auth.dto.TokenResponse;

public interface AuthService {

    TokenResponse register(RegisterRequest request);

    TokenResponse login(LoginRequest request);

    void logout(String refreshToken);

    TokenResponse refresh(String refreshToken);

    String forgotPassword(ForgotPasswordRequest request);

    void resetPassword(ResetPasswordRequest request);

    void changePassword(Long userId, ChangePasswordRequest request);
}