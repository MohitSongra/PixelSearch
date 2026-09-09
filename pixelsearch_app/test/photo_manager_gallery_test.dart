import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pixelsearch/indexing/adapters/photo_manager_gallery.dart';
import 'package:pixelsearch/indexing/model/folder_selection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluttercandies/photo_manager');
  final calls = <MethodCall>[];
  var permission = PermissionState.authorized;
  var folderName = 'Camera';
  final albums = <String, List<String>>{};

  setUp(() {
    permission = PermissionState.authorized;
    folderName = 'Camera';
    calls.clear();
    albums.clear();
    albums['camera'] = [for (var i = 0; i < 1101; i++) 'p$i'];
    albums['trip'] = ['p0', 'trip1'];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final args = call.arguments as Map?;
          final all = albums.values.expand((ids) => ids).toSet().toList();
          switch (call.method) {
            case 'requestPermissionExtend':
            case 'getPermissionState':
              expect(
                args!['androidPermission']['type'],
                RequestType.image.value,
              );
              return permission.index;
            case 'getAssetPathList':
              return {
                'data': [
                  if (args!['onlyAll'] == true)
                    {
                      'id': 'all',
                      'name': 'All',
                      'isAll': true,
                      'assetCount': all.length,
                    }
                  else
                    for (final id in albums.keys)
                      {
                        'id': id,
                        'name': folderName,
                        'isAll': false,
                        'assetCount': albums[id]!.length,
                      },
                ],
              };
            case 'getAssetCountFromPath':
              return args!['id'] == 'all'
                  ? all.length
                  : albums[args['id']]!.length;
            case 'getAssetListPaged':
              final ids = args!['id'] == 'all' ? all : albums[args['id']]!;
              final start = (args['page'] as int) * (args['size'] as int);
              return {
                'data': [
                  for (final id in ids.skip(start).take(args['size'] as int))
                    {
                      'id': id,
                      'type': 1,
                      'width': 2,
                      'height': 2,
                      'modifiedDt': 1,
                      'createDt': 1,
                    },
                ],
              };
            default:
              throw UnsupportedError(call.method);
          }
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test(
    'selected folder pages past 1000; other folders only supply existence metadata',
    () async {
      final snapshot = await PhotoManagerGallerySource(
        selection: FolderSelection(folderIds: {'camera'}),
      ).listAssets();
      expect(snapshot.assets.length, 1101);
      expect(snapshot.assets.every((a) => a.album == 'Camera'), isTrue);
      expect(snapshot.existingAssetIds, contains('trip1'));
      expect(
        calls
            .where(
              (c) =>
                  c.method == 'getAssetListPaged' &&
                  c.arguments['id'] == 'camera',
            )
            .map((c) => c.arguments['page']),
        [0, 1, 2],
      );
      expect(calls.any((c) => c.method == 'getOriginBytes'), isFalse);
      expect(snapshot.canDeleteMissing, isTrue);
    },
  );

  test(
    'multiple folders deduplicate assets and IDs survive a name change',
    () async {
      folderName = 'Renamed folder';
      final snapshot = await PhotoManagerGallerySource(
        selection: FolderSelection(folderIds: {'camera', 'trip'}),
      ).listAssets();
      expect(snapshot.assets.length, 1102);
      expect(snapshot.assets.where((a) => a.id == 'p0').length, 1);
    },
  );

  test('empty selection never scans or silently falls back to all', () async {
    final result = await PhotoManagerGallerySource(
      selection: FolderSelection(),
    ).listAssets();
    expect(result.assets, isEmpty);
    expect(result.canDeleteMissing, isFalse);
    expect(calls, isEmpty);
  });

  test('missing selected folder fails closed', () async {
    await expectLater(
      PhotoManagerGallerySource(
        selection: FolderSelection(folderIds: {'gone'}),
      ).listAssets(),
      throwsStateError,
    );
    expect(calls.where((c) => c.method == 'getAssetListPaged'), isEmpty);
  });

  test('limited permissions disable deletion reconciliation', () async {
    permission = PermissionState.limited;
    final result = await PhotoManagerGallerySource(
      selection: FolderSelection(folderIds: {'trip'}),
    ).listAssets();
    expect(result.assets.length, 2);
    expect(result.canDeleteMissing, isFalse);
    expect(
      calls
          .where((c) => c.method == 'getAssetListPaged')
          .every((c) => c.arguments['id'] == 'trip'),
      isTrue,
    );
  });

  test(
    'permission denied fails rather than presenting an empty gallery',
    () async {
      permission = PermissionState.denied;
      await expectLater(
        PhotoManagerGallerySource(
          selection: FolderSelection(allFolders: true),
        ).listAssets(),
        throwsStateError,
      );
    },
  );

  test('all folders uses one paged all-photos collection', () async {
    final result = await PhotoManagerGallerySource(
      selection: FolderSelection(allFolders: true),
    ).listAssets();
    expect(result.assets.length, 1102);
    expect(calls.where((c) => c.method == 'getAssetPathList').length, 1);
  });

  test(
    'folder picker inventory contains IDs, counts and limited-access state',
    () async {
      permission = PermissionState.limited;
      final result = await PhotoManagerGallerySource.listFolders();
      expect(result.limited, isTrue);
      expect(result.folders.map((f) => f.id).toSet(), {'camera', 'trip'});
      expect(result.folders.map((f) => f.count).toSet(), {1101, 2});
      expect(
        calls
            .where((c) => c.method == 'getAssetPathList')
            .single
            .arguments['hasAll'],
        false,
      );
    },
  );
}
