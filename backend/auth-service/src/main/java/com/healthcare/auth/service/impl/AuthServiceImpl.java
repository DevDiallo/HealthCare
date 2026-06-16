package com.healthcare.auth.service.impl;

import com.healthcare.auth.config.AppProperties;
import com.healthcare.auth.dto.ChangePasswordRequest;
import com.healthcare.auth.dto.ForgotPasswordRequest;
import com.healthcare.auth.dto.LoginRequest;
import com.healthcare.auth.dto.RegisterRequest;
import com.healthcare.auth.dto.ResetPasswordRequest;
import com.healthcare.auth.dto.TokenResponse;
import com.healthcare.auth.entity.PasswordResetToken;
import com.healthcare.auth.entity.RefreshToken;
import com.healthcare.auth.entity.UserAccount;
import com.healthcare.auth.entity.UserStatus;
import com.healthcare.auth.exception.BusinessException;
import com.healthcare.auth.exception.NotFoundException;
import com.healthcare.auth.exception.UnauthorizedException;
import com.healthcare.auth.mapper.AuthMapper;
import com.healthcare.auth.repository.PasswordResetTokenRepository;
import com.healthcare.auth.repository.RefreshTokenRepository;
import com.healthcare.auth.repository.UserAccountRepository;
import com.healthcare.auth.security.JwtService;
import com.healthcare.auth.service.AuthService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class AuthServiceImpl implements AuthService {

    private final UserAccountRepository userAccountRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AppProperties appProperties;

    @Override
    public TokenResponse register(RegisterRequest request) {
        if (userAccountRepository.existsByEmailIgnoreCase(request.email())) {
            throw new BusinessException("Email already registered");
        }

        UserAccount user = userAccountRepository.save(AuthMapper.toEntity(request, passwordEncoder.encode(request.password())));
        return issueTokens(user);
    }

    @Override
    public TokenResponse login(LoginRequest request) {
        UserAccount user = userAccountRepository.findByEmailIgnoreCase(request.email())
                .orElseThrow(() -> new UnauthorizedException("Invalid credentials"));

        if (!passwordEncoder.matches(request.password(), user.getPassword())) {
            throw new UnauthorizedException("Invalid credentials");
        }

        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new BusinessException("User account is not active");
        }

        return issueTokens(user);
    }

    @Override
    public void logout(String refreshToken) {
        RefreshToken token = refreshTokenRepository.findByTokenAndRevokedFalse(refreshToken)
                .orElseThrow(() -> new UnauthorizedException("Refresh token not found"));
        token.setRevoked(true);
        refreshTokenRepository.save(token);
    }

    @Override
    public TokenResponse refresh(String refreshToken) {
        RefreshToken token = refreshTokenRepository.findByTokenAndRevokedFalse(refreshToken)
                .orElseThrow(() -> new UnauthorizedException("Refresh token invalid"));
        if (token.getExpiresAt().isBefore(OffsetDateTime.now())) {
            token.setRevoked(true);
            throw new UnauthorizedException("Refresh token expired");
        }
        return issueTokens(token.getUser());
    }

    @Override
    public String forgotPassword(ForgotPasswordRequest request) {
        UserAccount user = userAccountRepository.findByEmailIgnoreCase(request.email())
                .orElseThrow(() -> new NotFoundException("User not found"));
        PasswordResetToken resetToken = passwordResetTokenRepository.save(PasswordResetToken.builder()
                .token(UUID.randomUUID().toString())
                .user(user)
                .expiresAt(OffsetDateTime.now().plusHours(2))
                .used(false)
                .build());
        return resetToken.getToken();
    }

    @Override
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetToken token = passwordResetTokenRepository.findByTokenAndUsedFalse(request.token())
                .orElseThrow(() -> new UnauthorizedException("Reset token invalid"));
        if (token.getExpiresAt().isBefore(OffsetDateTime.now())) {
            throw new UnauthorizedException("Reset token expired");
        }
        UserAccount user = token.getUser();
        user.setPassword(passwordEncoder.encode(request.newPassword()));
        userAccountRepository.save(user);
        token.setUsed(true);
        passwordResetTokenRepository.save(token);
    }

    @Override
    public void changePassword(Long userId, ChangePasswordRequest request) {
        UserAccount user = userAccountRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        if (!passwordEncoder.matches(request.currentPassword(), user.getPassword())) {
            throw new UnauthorizedException("Current password is invalid");
        }
        user.setPassword(passwordEncoder.encode(request.newPassword()));
        userAccountRepository.save(user);
    }

    private TokenResponse issueTokens(UserAccount user) {
        String accessToken = jwtService.generateAccessToken(user.getId(), user.getHospitalId(), user.getRole());
        String refreshToken = jwtService.generateRefreshToken(user.getId(), user.getHospitalId(), user.getRole());

        refreshTokenRepository.save(RefreshToken.builder()
                .token(refreshToken)
                .user(user)
                .expiresAt(OffsetDateTime.now().plusSeconds(appProperties.getRefreshExpiration() / 1000))
                .revoked(false)
                .build());

        return TokenResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .hospitalId(user.getHospitalId())
                .role(user.getRole())
                .tokenType("Bearer")
                .expiresIn(appProperties.getExpiration())
                .build();
    }
}