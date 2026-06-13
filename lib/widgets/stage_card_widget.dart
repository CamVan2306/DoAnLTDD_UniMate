import 'package:flutter/material.dart';

class StageCardWidget extends StatelessWidget {
  final String stageNumber;
  final String title;
  final String description;
  final String status; // 'CHƯA NỘP', 'ĐÃ NỘP', 'ĐÃ CHẤM'
  final Widget? extraContent;

  const StageCardWidget({
    Key? key,
    required this.stageNumber,
    required this.title,
    required this.description,
    required this.status,
    this.extraContent,
  }) : super(key: key);

  Color _getStatusColor() {
    String upperStatus = status.toUpperCase();
    switch (upperStatus) {
      case 'ĐÃ CHẤM':
        return Colors.green.shade100; // Giảng viên đã chấm xong
      case 'ĐÃ NỘP':
        return Colors.orange.shade100; // Sinh viên vừa nộp, chờ giảng viên chấm
      case 'CHƯA NỘP':
      default:
        return Colors.grey.shade200; // Chưa tới hạn hoặc chưa nộp
    }
  }

  Color _getStatusTextColor() {
    String upperStatus = status.toUpperCase();
    switch (upperStatus) {
      case 'ĐÃ CHẤM':
        return Colors.green.shade800;
      case 'ĐÃ NỘP':
        return Colors.orange.shade900;
      case 'CHƯA NỘP':
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stageNumber.toUpperCase(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Chip(
                label: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusTextColor(),
                  ),
                ),
                backgroundColor: _getStatusColor(),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          if (extraContent != null) ...[
            const SizedBox(height: 16),
            extraContent!,
          ],
        ],
      ),
    );
  }
}
