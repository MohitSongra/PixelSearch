import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import '../../core/theme.dart';
import '../../domain/gallery/indexed_gallery.dart';
import '../viewer/photo_viewer.dart';

class IndexedGalleryView extends StatefulWidget {
  const IndexedGalleryView({super.key, required this.gallery});
  final IndexedGallery gallery;

  @override
  State<IndexedGalleryView> createState() => _IndexedGalleryViewState();
}

class _IndexedGalleryViewState extends State<IndexedGalleryView> {
  final _scroll = ScrollController();
  GalleryLayout? _layout;
  IndexedGallery? _laidOut;
  bool _dragging = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _offset => _scroll.hasClients ? _scroll.offset : 0;
  int get _month => _layout!.entries[_layout!.entryAt(_offset)].day.monthIndex;

  void _jumpMonth(int month) {
    if (!_scroll.hasClients) return;
    final index = month.clamp(0, widget.gallery.months.length - 1);
    _scroll.jumpTo(
      _layout!.monthOffsets[index].clamp(
        0.0,
        math.max(
          0.0,
          _layout!.totalExtent - _scroll.position.viewportDimension,
        ),
      ),
    );
  }

  Future<void> _chooseMonth() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Jump to date',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.gallery.months.length,
                itemBuilder: (_, i) {
                  final month = widget.gallery.months[i];
                  return ListTile(
                    title: Text(Dates.monthYear(month.date)),
                    subtitle: Text('${month.count} photos'),
                    selected: i == _month,
                    onTap: () => Navigator.pop(context, i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) _jumpMonth(selected);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gallery.photos.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const railWidth = 40.0;
        final width = constraints.maxWidth - railWidth;
        final columns = (width / 128).floor().clamp(3, 8);
        final extent = (width - (columns - 1) * 2) / columns + 2;
        final header = math.max(
          48.0,
          MediaQuery.textScalerOf(context).scale(14) * 1.4 + 20,
        );
        if (_laidOut != widget.gallery ||
            _layout?.columns != columns ||
            _layout?.photoExtent != extent ||
            _layout?.headerExtent != header) {
          _laidOut = widget.gallery;
          _layout = GalleryLayout(
            widget.gallery,
            columns: columns,
            photoExtent: extent,
            headerExtent: header,
          );
        }
        final layout = _layout!;
        return Column(
          children: [
            AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) => Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('gallery-month-picker'),
                  onPressed: _chooseMonth,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    Dates.monthYear(widget.gallery.months[_month].date),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          key: const PageStorageKey('indexed-gallery-scroll'),
                          controller: _scroll,
                          padding: EdgeInsets.zero,
                          scrollCacheExtent: const ScrollCacheExtent.pixels(
                            300,
                          ),
                          addAutomaticKeepAlives: false,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: layout.entries.length,
                          itemExtentBuilder: (i, _) =>
                              i >= layout.entries.length
                              ? null
                              : layout.entries[i].isHeader
                              ? layout.headerExtent
                              : layout.photoExtent,
                          itemBuilder: (context, i) {
                            final row = layout.entries[i];
                            if (row.isHeader) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        Dates.short(row.day.date),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${row.day.count}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  for (
                                    var column = 0;
                                    column < columns;
                                    column++
                                  ) ...[
                                    if (column > 0) const SizedBox(width: 2),
                                    Expanded(
                                      child: column >= row.count
                                          ? const SizedBox()
                                          : _photo(context, row.start + column),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: railWidth,
                        child: AnimatedBuilder(
                          animation: _scroll,
                          builder: (context, _) {
                            final maxScroll = math.max(
                              0.0,
                              layout.totalExtent - viewport.maxHeight,
                            );
                            if (maxScroll == 0) return const SizedBox.shrink();
                            final travel = math.max(
                              0.0,
                              viewport.maxHeight - 56,
                            );
                            final fraction = (_offset / maxScroll).clamp(
                              0.0,
                              1.0,
                            );
                            void drag(double y) {
                              if (!_scroll.hasClients || travel == 0) return;
                              final position = ((y - 28) / travel).clamp(
                                0.0,
                                1.0,
                              );
                              _scroll.jumpTo(position * maxScroll);
                            }

                            return Semantics(
                              label: 'Scroll by date',
                              value: Dates.monthYear(
                                widget.gallery.months[_month].date,
                              ),
                              increasedValue: Dates.monthYear(
                                widget
                                    .gallery
                                    .months[(_month + 1).clamp(
                                      0,
                                      widget.gallery.months.length - 1,
                                    )]
                                    .date,
                              ),
                              decreasedValue: Dates.monthYear(
                                widget
                                    .gallery
                                    .months[(_month - 1).clamp(
                                      0,
                                      widget.gallery.months.length - 1,
                                    )]
                                    .date,
                              ),
                              slider: true,
                              onIncrease: () => _jumpMonth(_month + 1),
                              onDecrease: () => _jumpMonth(_month - 1),
                              child: GestureDetector(
                                key: const ValueKey('gallery-date-scrubber'),
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragStart: (details) {
                                  setState(() => _dragging = true);
                                  drag(details.localPosition.dy);
                                },
                                onVerticalDragUpdate: (details) =>
                                    drag(details.localPosition.dy),
                                onVerticalDragEnd: (_) =>
                                    setState(() => _dragging = false),
                                onVerticalDragCancel: () =>
                                    setState(() => _dragging = false),
                                onTapUp: (details) =>
                                    drag(details.localPosition.dy),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 2,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 28,
                                        ),
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4 + travel * fraction,
                                      left: 4,
                                      right: 4,
                                      height: 48,
                                      child: Tooltip(
                                        message: Dates.monthYear(
                                          widget.gallery.months[_month].date,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: _dragging
                                                ? scheme.primary
                                                : scheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.unfold_more,
                                            color: _dragging
                                                ? scheme.onPrimary
                                                : scheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _photo(BuildContext context, int index) {
    final photo = widget.gallery.photos[index];
    return Semantics(
      label: '${photo.displayTitle}, ${Dates.short(photo.date.toLocal())}',
      button: true,
      child: InkWell(
        key: ValueKey('indexed-photo-${photo.id}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => PhotoViewerScreen(
              photos: widget.gallery.photos,
              initialIndex: index,
            ),
          ),
        ),
        child: SizedBox.expand(
          child: Image(
            image: photo.image,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }
}
