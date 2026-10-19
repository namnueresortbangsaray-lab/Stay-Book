// โครงสร้างข้อมูลสรุปตามช่วงวันที่สำหรับการ์ดและกราฟบน Dashboard

class DailyRevenue {
  const DailyRevenue(this.date, this.amount);
  final String date;
  final double amount;
}

class DailyOccupancy {
  const DailyOccupancy(this.date, this.occupiedRoomNights, this.totalRooms);
  final String date;
  final int occupiedRoomNights;
  final int totalRooms;
  double get rate => totalRooms == 0 ? 0 : occupiedRoomNights / totalRooms;
}

class BookingStatusSummary {
  const BookingStatusSummary({
    required this.booked,
    required this.checkedIn,
    required this.checkedOut,
  });
  final int booked;
  final int checkedIn;
  final int checkedOut;
  int get total => booked + checkedIn + checkedOut;
}

class DepositSummary {
  const DepositSummary({
    required this.none,
    required this.paid,
    required this.unpaid,
  });
  final int none;
  final int paid;
  final int unpaid;
  int get total => none + paid + unpaid;
}

class DashboardRangeData {
  const DashboardRangeData({
    required this.startDate,
    required this.endDate,
    required this.totalRooms,
    required this.bookingCount,
    required this.checkInCount,
    required this.checkOutCount,
    required this.guestCount,
    required this.occupiedRoomNights,
    required this.grossRevenue,
    required this.totalDiscount,
    required this.netRevenue,
    required this.depositReceived,
    required this.depositPending,
    required this.petBookings,
    required this.averageFeedback,
    required this.revenueChart,
    required this.occupancyChart,
    required this.bookingStatuses,
    required this.depositStatuses,
  });
  final String startDate;
  final String endDate;
  final int totalRooms;
  final int bookingCount;
  final int checkInCount;
  final int checkOutCount;
  final int guestCount;
  final int occupiedRoomNights;
  final double grossRevenue;
  final double totalDiscount;
  final double netRevenue;
  final double depositReceived;
  final double depositPending;
  final int petBookings;
  final double averageFeedback;
  final List<DailyRevenue> revenueChart;
  final List<DailyOccupancy> occupancyChart;
  final BookingStatusSummary bookingStatuses;
  final DepositSummary depositStatuses;
  int get dayCount =>
      DateTime.parse(endDate).difference(DateTime.parse(startDate)).inDays + 1;
  double get occupancyRate => totalRooms == 0 || dayCount == 0
      ? 0
      : occupiedRoomNights / (totalRooms * dayCount);
  int get occupiedRoomsAtEnd =>
      occupancyChart.isEmpty ? 0 : occupancyChart.last.occupiedRoomNights;
  int get vacantRoomsAtEnd => totalRooms - occupiedRoomsAtEnd;
}
