import '../../models/photo.dart';

class GalleryDay {
  const GalleryDay(this.date, this.start, this.count, this.monthIndex);
  final DateTime date;
  final int start, count, monthIndex;
}

class GalleryMonth {
  const GalleryMonth(this.date, this.count);
  final DateTime date;
  final int count;
}

/// A metadata-only projection of the persisted library, never device discovery.
class IndexedGallery {
  IndexedGallery(Iterable<Photo> source) {
    final sorted = source.toList()
      ..sort((a, b) {
        final date = b.date.compareTo(a.date);
        return date != 0 ? date : a.id.compareTo(b.id);
      });
    photos = List.unmodifiable(sorted);
    final groupedDays = <GalleryDay>[];
    final groupedMonths = <GalleryMonth>[];
    var start = 0;
    while (start < photos.length) {
      final date = photos[start].date.toLocal();
      final day = DateTime(date.year, date.month, date.day);
      var end = start + 1;
      while (end < photos.length) {
        final next = photos[end].date.toLocal();
        if (next.year != day.year ||
            next.month != day.month ||
            next.day != day.day) {
          break;
        }
        end++;
      }
      final month = DateTime(day.year, day.month);
      if (groupedMonths.isEmpty || groupedMonths.last.date != month) {
        groupedMonths.add(GalleryMonth(month, 0));
      }
      final monthIndex = groupedMonths.length - 1;
      groupedMonths[monthIndex] = GalleryMonth(
        month,
        groupedMonths.last.count + end - start,
      );
      groupedDays.add(GalleryDay(day, start, end - start, monthIndex));
      start = end;
    }
    days = List.unmodifiable(groupedDays);
    months = List.unmodifiable(groupedMonths);
  }

  late final List<Photo> photos;
  late final List<GalleryDay> days;
  late final List<GalleryMonth> months;
}

class GalleryRow {
  const GalleryRow(this.day, this.start, this.count, {this.isHeader = false});
  final GalleryDay day;
  final int start, count;
  final bool isHeader;
}

/// Known row extents allow lazy grids and exact date jumps without decoding images.
class GalleryLayout {
  GalleryLayout(
    IndexedGallery gallery, {
    required this.columns,
    required this.photoExtent,
    required this.headerExtent,
  }) {
    final rows = <GalleryRow>[];
    final positions = <double>[];
    final months = <double>[];
    var offset = 0.0;
    for (final day in gallery.days) {
      if (months.length <= day.monthIndex) months.add(offset);
      positions.add(offset);
      rows.add(GalleryRow(day, day.start, day.count, isHeader: true));
      offset += headerExtent;
      for (
        var start = day.start;
        start < day.start + day.count;
        start += columns
      ) {
        positions.add(offset);
        final count = (day.start + day.count - start).clamp(0, columns);
        rows.add(GalleryRow(day, start, count));
        offset += photoExtent;
      }
    }
    entries = List.unmodifiable(rows);
    offsets = List.unmodifiable(positions);
    monthOffsets = List.unmodifiable(months);
    totalExtent = offset;
  }

  final int columns;
  final double photoExtent, headerExtent;
  late final List<GalleryRow> entries;
  late final List<double> offsets, monthOffsets;
  late final double totalExtent;

  int entryAt(double offset) {
    if (entries.isEmpty) return 0;
    var low = 0;
    var high = offsets.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (offsets[middle] <= offset) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return (low - 1).clamp(0, entries.length - 1);
  }
}
