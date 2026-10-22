import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliver, ScrollCacheExtent;
import '../../core/theme.dart';
import '../../domain/gallery/indexed_gallery.dart';
import '../viewer/photo_viewer.dart';

/// Dates and rows have known extents, so scrolling never needs an estimate
/// derived from whichever mix of headers and photos is currently on screen.
class _GalleryChildren extends SliverChildBuilderDelegate {
  _GalleryChildren({
    required NullableIndexedWidgetBuilder builder,
    required int childCount,
    required this.totalExtent,
  }) : super(builder, childCount: childCount, addAutomaticKeepAlives: false);

  final double totalExtent;

  @override
  double estimateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) => totalExtent;
}

class IndexedGalleryView extends StatefulWidget {
  const IndexedGalleryView({
    super.key,
    required this.gallery,
    this.headerBuilder,
    this.introduction,
    this.pinnedHeader,
    this.beforeGallery,
    this.emptyContent,
  });
  final IndexedGallery gallery;
  final Widget Function(VoidCallback? chooseMonth, DateTime? month)?
  headerBuilder;
  final Widget? introduction;
  final Widget? pinnedHeader;
  final Widget? beforeGallery;
  final Widget? emptyContent;

  @override
  State<IndexedGalleryView> createState() => _IndexedGalleryViewState();
}

class _IndexedGalleryViewState extends State<IndexedGalleryView> {
  final _scroll = ScrollController();
  final _pinnedKey = GlobalKey();
  GalleryLayout? _layout;
  IndexedGallery? _laidOut;
  double _galleryStart = 0;
  double _pinnedExtent = 0;
  bool _geometryReady = false;
  bool _geometryUpdateScheduled = false;
  bool _dragging = false;
  double _scrubStartY = 0;
  double _scrubStartOffset = 0;
  double _scrubTravel = 1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double get _offset => _scroll.hasClients ? _scroll.offset : 0;
  double get _galleryOffset =>
      math.max(0, _offset + _pinnedExtent - _galleryStart);
  int get _month =>
      _layout!.entries[_layout!.entryAt(_galleryOffset)].day.monthIndex;

  void _recordGeometry(double galleryStart) {
    final renderHeader =
        _pinnedKey.currentContext?.findRenderObject() as RenderSliver?;
    final pinnedExtent =
        renderHeader?.geometry?.maxScrollObstructionExtent ?? 0;
    if (_geometryReady &&
        galleryStart == _galleryStart &&
        pinnedExtent == _pinnedExtent) {
      return;
    }
    _galleryStart = galleryStart;
    _pinnedExtent = pinnedExtent;
    _geometryReady = true;
    if (_geometryUpdateScheduled) return;
    _geometryUpdateScheduled = true;
    // Geometry is known during sliver layout; redraw the overlay after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryUpdateScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _jumpMonth(int month) {
    if (!_scroll.hasClients || widget.gallery.months.isEmpty) return;
    final index = month.clamp(0, widget.gallery.months.length - 1);
    _scroll.jumpTo(
      (_galleryStart + _layout!.monthOffsets[index] - _pinnedExtent).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
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
    final scheme = Theme.of(context).colorScheme;
    final hasPhotos = widget.gallery.photos.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 48 || constraints.maxHeight < 100) {
          return const SizedBox.shrink();
        }
        final width = constraints.maxWidth - 24;
        final columns = (width / 128).floor().clamp(3, 8);
        final extent = (width - (columns - 1) * 3) / columns + 3;
        final header = math.max(
          32.0,
          MediaQuery.textScalerOf(context).scale(14) * 1.4 + 12,
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
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomScrollView(
                key: const PageStorageKey('indexed-gallery-scroll'),
                controller: _scroll,
                scrollCacheExtent: const ScrollCacheExtent.pixels(300),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  if (widget.introduction != null)
                    SliverToBoxAdapter(child: widget.introduction),
                  if (widget.pinnedHeader != null)
                    PinnedHeaderSliver(
                      key: _pinnedKey,
                      child: ColoredBox(
                        key: const ValueKey('home-search-header'),
                        color: scheme.surface,
                        child: widget.pinnedHeader,
                      ),
                    ),
                  if (widget.beforeGallery != null)
                    SliverToBoxAdapter(child: widget.beforeGallery),
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _scroll,
                      builder: (context, _) =>
                          widget.headerBuilder?.call(
                            hasPhotos ? _chooseMonth : null,
                            hasPhotos
                                ? widget.gallery.months[_month].date
                                : null,
                          ) ??
                          (hasPhotos
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    key: const ValueKey('gallery-month-picker'),
                                    onPressed: _chooseMonth,
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      Dates.monthYear(
                                        widget.gallery.months[_month].date,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()),
                    ),
                  ),
                  if (hasPhotos)
                    SliverLayoutBuilder(
                      builder: (context, sliverConstraints) {
                        _recordGeometry(
                          sliverConstraints.precedingScrollExtent,
                        );
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverVariedExtentList(
                            itemExtentBuilder: (i, _) =>
                                i >= layout.entries.length
                                ? null
                                : layout.entries[i].isHeader
                                ? layout.headerExtent
                                : layout.photoExtent,
                            delegate: _GalleryChildren(
                              totalExtent: layout.totalExtent,
                              childCount: layout.entries.length,
                              builder: (context, i) {
                                final row = layout.entries[i];
                                if (row.isHeader) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      60,
                                      0,
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
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    children: [
                                      for (
                                        var column = 0;
                                        column < columns;
                                        column++
                                      ) ...[
                                        if (column > 0)
                                          const SizedBox(width: 3),
                                        Expanded(
                                          child: column >= row.count
                                              ? const SizedBox()
                                              : _photo(
                                                  context,
                                                  row.start + column,
                                                ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    )
                  else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: widget.emptyContent ?? const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
            if (hasPhotos)
              AnimatedBuilder(
                animation: _scroll,
                builder: (context, _) {
                  if (!_geometryReady ||
                      !_scroll.hasClients ||
                      !_scroll.position.hasContentDimensions) {
                    return const SizedBox.shrink();
                  }
                  final maxScroll = _scroll.position.maxScrollExtent;
                  if (maxScroll <= 0) return const SizedBox.shrink();
                  final minTop = math.min(
                    _pinnedExtent,
                    constraints.maxHeight - 56,
                  );
                  final galleryTop = (_galleryStart - _offset).clamp(
                    minTop,
                    constraints.maxHeight - 56,
                  );
                  final travel = math.max(
                    0.0,
                    constraints.maxHeight - galleryTop - 56,
                  );
                  final fraction = (_offset / maxScroll).clamp(0.0, 1.0);
                  void drag(double globalY) {
                    final position =
                        (_scrubStartOffset +
                                (globalY - _scrubStartY) /
                                    _scrubTravel *
                                    maxScroll)
                            .clamp(0.0, maxScroll);
                    _scroll.jumpTo(position);
                  }

                  return Positioned(
                    right: 12,
                    top: galleryTop + 4 + travel * fraction,
                    width: 48,
                    height: 48,
                    child: Semantics(
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
                        onVerticalDragDown: (details) {
                          _scrubStartY = details.globalPosition.dy;
                          _scrubStartOffset = _offset;
                          _scrubTravel = math.max(1.0, travel);
                        },
                        onVerticalDragStart: (details) {
                          setState(() => _dragging = true);
                          drag(details.globalPosition.dy);
                        },
                        onVerticalDragUpdate: (details) =>
                            drag(details.globalPosition.dy),
                        onVerticalDragEnd: (_) =>
                            setState(() => _dragging = false),
                        onVerticalDragCancel: () =>
                            setState(() => _dragging = false),
                        onTap: _chooseMonth,
                        child: Tooltip(
                          message: Dates.monthYear(
                            widget.gallery.months[_month].date,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _dragging
                                  ? scheme.primary
                                  : scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
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
                    ),
                  );
                },
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
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(
            builder: (_) => PhotoViewerScreen(
              photos: widget.gallery.photos,
              initialIndex: index,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }
}
