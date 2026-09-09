class FolderSelection {
  FolderSelection({this.allFolders = false, Set<String> folderIds = const {}})
    : folderIds = Set.unmodifiable(folderIds);

  final bool allFolders;
  final Set<String> folderIds;
  bool get isEmpty => !allFolders && folderIds.isEmpty;
}

class GalleryFolder {
  const GalleryFolder({
    required this.id,
    required this.name,
    required this.count,
    this.relativePath,
  });
  final String id;
  final String name;
  final int count;
  final String? relativePath;
}

class FolderCatalog {
  const FolderCatalog(this.folders, {this.limited = false});
  final List<GalleryFolder> folders;
  final bool limited;
}
