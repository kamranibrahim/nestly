import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    required this.color,
    required this.initials,
  });

  final String id;
  final String name;
  final String role;
  final Color color;
  final String initials;
}

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.time,
    required this.memberId,
    required this.category,
    this.location,
  });

  final String title;
  final String time;
  final String memberId;
  final String category;
  final String? location;
}

class ExpenseItem {
  const ExpenseItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.by,
    required this.when,
  });

  final String title;
  final String category;
  final double amount;
  final String by;
  final String when;
}

class BillItem {
  const BillItem({
    required this.title,
    required this.amount,
    required this.dueLabel,
    required this.paid,
  });

  final String title;
  final double amount;
  final String dueLabel;
  final bool paid;
}

class VaultDoc {
  const VaultDoc({
    required this.title,
    required this.category,
    required this.updated,
    required this.icon,
  });

  final String title;
  final String category;
  final String updated;
  final IconData icon;
}

class TimelineItem {
  const TimelineItem({
    required this.text,
    required this.time,
    required this.memberId,
  });

  final String text;
  final String time;
  final String memberId;
}

class EmergencyInfo {
  const EmergencyInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

abstract final class MockData {
  static const familyName = 'The Ibrahims';

  static const members = [
    FamilyMember(
      id: 'dad',
      name: 'Kamran',
      role: 'Dad',
      color: AppColors.tileBlue,
      initials: 'K',
    ),
    FamilyMember(
      id: 'mom',
      name: 'Sara',
      role: 'Mom',
      color: AppColors.tilePink,
      initials: 'S',
    ),
    FamilyMember(
      id: 'ayaan',
      name: 'Ayaan',
      role: 'Son',
      color: AppColors.tileGreen,
      initials: 'A',
    ),
    FamilyMember(
      id: 'noor',
      name: 'Noor',
      role: 'Daughter',
      color: AppColors.tileOrange,
      initials: 'N',
    ),
  ];

  static FamilyMember memberById(String id) =>
      members.firstWhere((m) => m.id == id, orElse: () => members.first);

  static const todayEvents = [
    CalendarEvent(
      title: 'School drop-off',
      time: '7:45 AM',
      memberId: 'dad',
      category: 'School',
      location: 'Greenfield Academy',
    ),
    CalendarEvent(
      title: 'Dentist — Noor',
      time: '11:30 AM',
      memberId: 'mom',
      category: 'Health',
      location: 'SmileCare Clinic',
    ),
    CalendarEvent(
      title: 'Soccer practice',
      time: '4:30 PM',
      memberId: 'ayaan',
      category: 'Sports',
      location: 'City Field B',
    ),
    CalendarEvent(
      title: 'Family dinner',
      time: '7:00 PM',
      memberId: 'mom',
      category: 'Family',
    ),
  ];

  static const upcomingEvents = [
    CalendarEvent(
      title: 'Parent-teacher meeting',
      time: 'Tomorrow · 3:00 PM',
      memberId: 'dad',
      category: 'School',
    ),
    CalendarEvent(
      title: 'Ayaan’s birthday',
      time: 'Sat · All day',
      memberId: 'ayaan',
      category: 'Birthday',
    ),
    CalendarEvent(
      title: 'Car service',
      time: 'Mon · 10:00 AM',
      memberId: 'dad',
      category: 'Home',
    ),
  ];

  static const expenses = [
    ExpenseItem(
      title: 'Weekly groceries',
      category: 'Groceries',
      amount: 86.40,
      by: 'Kamran',
      when: 'Today',
    ),
    ExpenseItem(
      title: 'Fuel',
      category: 'Transport',
      amount: 42.00,
      by: 'Sara',
      when: 'Yesterday',
    ),
    ExpenseItem(
      title: 'School supplies',
      category: 'Kids',
      amount: 28.50,
      by: 'Sara',
      when: 'Mon',
    ),
    ExpenseItem(
      title: 'Plumbing fix',
      category: 'Home',
      amount: 120.00,
      by: 'Kamran',
      when: 'Sun',
    ),
  ];

  static const bills = [
    BillItem(
      title: 'Electricity',
      amount: 64.20,
      dueLabel: 'Due in 3 days',
      paid: false,
    ),
    BillItem(
      title: 'Internet',
      amount: 49.99,
      dueLabel: 'Due Fri',
      paid: false,
    ),
    BillItem(
      title: 'Water',
      amount: 22.50,
      dueLabel: 'Paid',
      paid: true,
    ),
    BillItem(
      title: 'Rent',
      amount: 1450.00,
      dueLabel: 'Due 1st',
      paid: false,
    ),
  ];

  static const vault = [
    VaultDoc(
      title: 'Passports',
      category: 'IDs',
      updated: '2 weeks ago',
      icon: Icons.badge_outlined,
    ),
    VaultDoc(
      title: 'Car insurance',
      category: 'Vehicle',
      updated: 'Yesterday',
      icon: Icons.directions_car_outlined,
    ),
    VaultDoc(
      title: 'Birth certificates',
      category: 'IDs',
      updated: 'Mar 12',
      icon: Icons.description_outlined,
    ),
    VaultDoc(
      title: 'Home warranty',
      category: 'Home',
      updated: 'Jan 8',
      icon: Icons.home_work_outlined,
    ),
    VaultDoc(
      title: 'School records',
      category: 'Kids',
      updated: 'Last week',
      icon: Icons.school_outlined,
    ),
  ];

  static const timeline = [
    TimelineItem(
      text: 'Kamran completed grocery shopping',
      time: '20m ago',
      memberId: 'dad',
    ),
    TimelineItem(
      text: 'Sara uploaded car insurance',
      time: '1h ago',
      memberId: 'mom',
    ),
    TimelineItem(
      text: 'Noor watered the plants',
      time: '2h ago',
      memberId: 'noor',
    ),
    TimelineItem(
      text: 'Ayaan added soccer practice',
      time: 'Yesterday',
      memberId: 'ayaan',
    ),
    TimelineItem(
      text: 'Electricity bill marked as paid',
      time: 'Yesterday',
      memberId: 'dad',
    ),
  ];

  static const emergency = [
    EmergencyInfo(
      label: 'Emergency contact',
      value: 'Omar Ibrahim · +1 555 0142',
      icon: Icons.phone_in_talk_outlined,
    ),
    EmergencyInfo(
      label: 'Family doctor',
      value: 'Dr. Patel · City Care',
      icon: Icons.medical_services_outlined,
    ),
    EmergencyInfo(
      label: 'Nearest hospital',
      value: 'Riverside General · 8 min',
      icon: Icons.local_hospital_outlined,
    ),
    EmergencyInfo(
      label: 'Allergies',
      value: 'Ayaan — peanuts · Noor — none',
      icon: Icons.warning_amber_rounded,
    ),
    EmergencyInfo(
      label: 'Blood groups',
      value: 'K O+ · S A+ · A B+ · N O+',
      icon: Icons.bloodtype_outlined,
    ),
    EmergencyInfo(
      label: 'Insurance',
      value: 'HealthPlus Family · #HP-88241',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  static const monthSpent = 1247.80;
  static const monthBudget = 1800.0;
}
