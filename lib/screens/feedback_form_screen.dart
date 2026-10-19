// แบบประเมิน Prototype บันทึกหนึ่งรายการต่อหนึ่ง Stay บน SQLite เครื่องนี้
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/checkout_inspection.dart';
import '../theme/app_theme.dart';

class FeedbackFormScreen extends StatefulWidget {
  const FeedbackFormScreen({super.key, required this.stayId});
  final int stayId;
  @override
  State<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends State<FeedbackFormScreen> {
  final TextEditingController _comment = TextEditingController();
  int _clean = 0, _service = 0, _facility = 0, _overall = 0;
  bool _return = true;
  GuestFeedback? _existing;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await DatabaseHelper.instance.getFeedbackByStayId(
      widget.stayId,
    );
    if (!mounted) return;
    setState(() {
      _existing = value;
      if (value != null) {
        _clean = value.cleanlinessRating;
        _service = value.serviceRating;
        _facility = value.facilityRating;
        _overall = value.overallRating;
        _return = value.wouldReturn;
        _comment.text = value.comment ?? '';
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (<int>[_clean, _service, _facility, _overall].contains(0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาให้คะแนนครบทุกหัวข้อ')),
      );
      return;
    }
    final value = GuestFeedback(
      id: _existing?.id,
      stayId: widget.stayId,
      cleanlinessRating: _clean,
      serviceRating: _service,
      facilityRating: _facility,
      overallRating: _overall,
      wouldReturn: _return,
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      createdAt: _existing?.createdAt ?? DateTime.now().toIso8601String(),
    );
    if (_existing == null) {
      await DatabaseHelper.instance.insertFeedback(value);
    } else {
      await DatabaseHelper.instance.updateFeedback(value);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _existing == null ? 'แบบประเมินการเข้าพัก' : 'แก้ไขแบบประเมิน',
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const Text(
                'Prototype: กรอกบนอุปกรณ์ของรีสอร์ตเครื่องนี้',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _rating('ความสะอาด', _clean, (v) => setState(() => _clean = v)),
              _rating(
                'การบริการ',
                _service,
                (v) => setState(() => _service = v),
              ),
              _rating(
                'สิ่งอำนวยความสะดวก',
                _facility,
                (v) => setState(() => _facility = v),
              ),
              _rating(
                'คะแนนรวม',
                _overall,
                (v) => setState(() => _overall = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _return,
                onChanged: (v) => setState(() => _return = v),
                title: const Text('ต้องการกลับมาใช้บริการอีก'),
              ),
              TextField(
                controller: _comment,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'ความคิดเห็นเพิ่มเติม',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('บันทึกแบบประเมิน'),
              ),
            ],
          ),
  );
  Widget _rating(String label, int value, ValueChanged<int> changed) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        Row(
          children: List<Widget>.generate(
            5,
            (i) => IconButton(
              onPressed: () => changed(i + 1),
              icon: Icon(
                i < value ? Icons.star : Icons.star_border,
                color: AppColors.warning,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
