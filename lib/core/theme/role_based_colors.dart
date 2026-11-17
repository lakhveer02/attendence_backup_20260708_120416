import 'package:flutter/material.dart';

/// Role-based color schemes for visual hierarchy and brand identity
/// Each role gets a distinct color palette for better UX and role recognition
class RoleBasedColors {
  // Super Admin - Royal Purple & Gold (Authority & Platform Owner)
  static const superAdminPrimary = Color(0xFF7C3AED); // Deep Purple
  static const superAdminAccent = Color(0xFFFCD34D); // Gold
  static const superAdminLight = Color(0xFFF3E8FF); // Light Purple
  static const superAdminDark = Color(0xFF5B21B6); // Dark Purple
  static const superAdminGradient = [Color(0xFF7C3AED), Color(0xFF6D28D9)];

  // Company Admin - Ocean Blue & Emerald (Trust & Leadership)
  static const companyAdminPrimary = Color(0xFF0EA5E9); // Bright Blue
  static const companyAdminAccent = Color(0xFF10B981); // Emerald Green
  static const companyAdminLight = Color(0xFFE0F2FE); // Light Blue
  static const companyAdminDark = Color(0xFF0369A1); // Dark Blue
  static const companyAdminGradient = [Color(0xFF0EA5E9), Color(0xFF06B6D4)];

  // HR Manager - Warm Coral & Sky Blue (People Management)
  static const hrManagerPrimary = Color(0xFFF97316); // Coral Orange
  static const hrManagerAccent = Color(0xFF3B82F6); // Sky Blue
  static const hrManagerLight = Color(0xFFFFEDD5); // Light Coral
  static const hrManagerDark = Color(0xFFC2410C); // Dark Coral
  static const hrManagerGradient = [Color(0xFFF97316), Color(0xFFFB923C)];

  // Team Manager - Forest Green & Navy (Team Leadership)
  static const teamManagerPrimary = Color(0xFF16A34A); // Forest Green
  static const teamManagerAccent = Color(0xFF1E40AF); // Navy Blue
  static const teamManagerLight = Color(0xFFDCFCE7); // Light Green
  static const teamManagerDark = Color(0xFF15803D); // Dark Green
  static const teamManagerGradient = [Color(0xFF16A34A), Color(0xFF059669)];

  // Employee - Modern Slate & Cyan (Individual Contributor)
  static const employeePrimary = Color(0xFF64748B); // Slate
  static const employeeAccent = Color(0xFF06B6D4); // Cyan
  static const employeeLight = Color(0xFFF1F5F9); // Light Slate
  static const employeeDark = Color(0xFF334155); // Dark Slate
  static const employeeGradient = [Color(0xFF64748B), Color(0xFF475569)];

  // Neutral palette for shared components
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF97316);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const disabled = Color(0xFFCBD5E1);

  // Get color scheme by role
  static ColorScheme getColorSchemeByRole(String role, {bool isDark = true}) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return ColorScheme.fromSeed(
          seedColor: superAdminPrimary,
          brightness: isDark ? Brightness.dark : Brightness.light,
        );
      case 'company_admin':
        return ColorScheme.fromSeed(
          seedColor: companyAdminPrimary,
          brightness: isDark ? Brightness.dark : Brightness.light,
        );
      case 'hr_manager':
        return ColorScheme.fromSeed(
          seedColor: hrManagerPrimary,
          brightness: isDark ? Brightness.dark : Brightness.light,
        );
      case 'team_manager':
      case 'manager':
        return ColorScheme.fromSeed(
          seedColor: teamManagerPrimary,
          brightness: isDark ? Brightness.dark : Brightness.light,
        );
      case 'employee':
      default:
        return ColorScheme.fromSeed(
          seedColor: employeePrimary,
          brightness: isDark ? Brightness.dark : Brightness.light,
        );
    }
  }

  // Get role accent color for badges, icons, etc.
  static Color getRoleAccentColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return superAdminAccent;
      case 'company_admin':
        return companyAdminAccent;
      case 'hr_manager':
        return hrManagerAccent;
      case 'team_manager':
      case 'manager':
        return teamManagerAccent;
      case 'employee':
      default:
        return employeeAccent;
    }
  }

  // Get role primary color
  static Color getRolePrimaryColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return superAdminPrimary;
      case 'company_admin':
        return companyAdminPrimary;
      case 'hr_manager':
        return hrManagerPrimary;
      case 'team_manager':
      case 'manager':
        return teamManagerPrimary;
      case 'employee':
      default:
        return employeePrimary;
    }
  }

  // Get role light background color
  static Color getRoleLightColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return superAdminLight;
      case 'company_admin':
        return companyAdminLight;
      case 'hr_manager':
        return hrManagerLight;
      case 'team_manager':
      case 'manager':
        return teamManagerLight;
      case 'employee':
      default:
        return employeeLight;
    }
  }

  // Get role gradient
  static List<Color> getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return superAdminGradient;
      case 'company_admin':
        return companyAdminGradient;
      case 'hr_manager':
        return hrManagerGradient;
      case 'team_manager':
      case 'manager':
        return teamManagerGradient;
      case 'employee':
      default:
        return employeeGradient;
    }
  }
}
