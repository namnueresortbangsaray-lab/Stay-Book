// รายชื่อลูกค้า ค้นหา กรอง เรียง และเปิดประวัติรายบุคคล
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../db/database_helper.dart';
import '../models/guest.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'guest_detail_screen.dart';

class GuestListScreen extends StatefulWidget {
  const GuestListScreen({super.key});
  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends State<GuestListScreen> {
  final TextEditingController _search = TextEditingController();
  bool _regular = false;
  String _sort = 'latest';
  String? _customerType;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_search),
                  labelText: 'ค้นหาชื่อหรือเบอร์โทร',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  FilterChip(
                    label: const Text('เฉพาะลูกค้าประจำ'),
                    selected: _regular,
                    onSelected: (v) => setState(() => _regular = v),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _sort,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'latest', child: Text('ล่าสุด')),
                      DropdownMenuItem(
                        value: 'count',
                        child: Text('จำนวนครั้ง'),
                      ),
                      DropdownMenuItem(value: 'value', child: Text('ยอดสะสม')),
                      DropdownMenuItem(value: 'name', child: Text('ชื่อ')),
                    ],
                    onChanged: (v) => setState(() => _sort = v!),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _customerType,
                decoration: const InputDecoration(labelText: 'ประเภทลูกค้า'),
                items: const <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ทุกประเภท'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ลูกค้าใหม่',
                    child: Text('ลูกค้าใหม่'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ลูกค้าทั่วไป',
                    child: Text('ลูกค้าทั่วไป'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ลูกค้าประจำ',
                    child: Text('ลูกค้าประจำ'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ลูกค้า VIP',
                    child: Text('ลูกค้า VIP'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ลูกค้าองค์กร',
                    child: Text('ลูกค้าองค์กร'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ลูกค้ากลุ่มหรือทัวร์',
                    child: Text('ลูกค้ากลุ่มหรือทัวร์'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'ลูกค้าจากตัวแทน',
                    child: Text('ลูกค้าจากตัวแทน'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'อื่น ๆ',
                    child: Text('อื่น ๆ'),
                  ),
                ],
                onChanged: (String? value) =>
                    setState(() => _customerType = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: dbRevision,
            builder: (context, revision, child) =>
                FutureBuilder<List<GuestSummary>>(
                  future: DatabaseHelper.instance.searchGuests(
                    keyword: _search.text,
                    regularOnly: _regular,
                    customerType: _customerType,
                    sort: _sort,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: TextButton(
                          onPressed: () => setState(() {}),
                          child: Text(
                            'โหลดไม่สำเร็จ · ลองใหม่\n${snapshot.error}',
                          ),
                        ),
                      );
                    }
                    final List<GuestSummary> values =
                        snapshot.data ?? <GuestSummary>[];
                    if (values.isEmpty) {
                      return const EmptyState(
                        icon: Icons.people_outline,
                        title: 'ยังไม่พบลูกค้า',
                        hint:
                            'ระบบสร้างโปรไฟล์เมื่อบันทึก Booking ที่มีเบอร์โทร',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                      itemCount: values.length,
                      itemBuilder: (context, index) {
                        final GuestSummary value = values[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GuestDetailScreen(
                                    guestId: value.guest.id!,
                                  ),
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  value.guest.name.characters.first,
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              title: Text(
                                value.guest.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${value.guest.phone}\n${value.completedStays} ครั้ง · ${value.totalNights} คืน · ${formatBaht(value.lifetimeValue)}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  if (value.guest.isRegular)
                                    const Icon(
                                      Icons.workspace_premium,
                                      color: AppColors.warning,
                                    ),
                                  Text(
                                    value.guest.customerType,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }
}
