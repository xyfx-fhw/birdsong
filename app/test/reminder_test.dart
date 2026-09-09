import 'package:birdsong_app/services/reminder_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseTime 解析 HH:mm', () {
    expect(ReminderService.parseTime('08:30'), const TimeOfDay(hour: 8, minute: 30));
    expect(ReminderService.parseTime(null), isNull);
  });

  test('formatTime 往返一致', () {
    const t = TimeOfDay(hour: 21, minute: 5);
    expect(ReminderService.parseTime(ReminderService.formatTime(t)), t);
  });
}
