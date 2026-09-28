import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:dart_git/dart_git.dart';
import 'package:dart_git/plumbing/index.dart';
import 'package:dart_git/plumbing/objects/blob.dart';
import 'package:dart_git/plumbing/objects/tree.dart';
import 'package:dart_git/utils/file_mode.dart';

void main() {
  group('GitFileMode.canonicalize', () {
    test('regular files keep only the executable bit', () {
      expect(GitFileMode.canonicalize(GitFileMode.parse('100644')),
          GitFileMode.Regular);
      expect(GitFileMode.canonicalize(GitFileMode.parse('100755')),
          GitFileMode.Executable);
      // Malformed modes produced from raw stat.mode (e.g. 0600/0660 perms)
      expect(GitFileMode.canonicalize(GitFileMode.parse('100600')),
          GitFileMode.Regular);
      expect(GitFileMode.canonicalize(GitFileMode.parse('100660')),
          GitFileMode.Regular);
      expect(GitFileMode.canonicalize(GitFileMode.parse('100700')),
          GitFileMode.Executable);
    });

    test('symlink, submodule and dir pass through', () {
      expect(GitFileMode.canonicalize(GitFileMode.Symlink),
          GitFileMode.Symlink);
      expect(GitFileMode.canonicalize(GitFileMode.Submodule),
          GitFileMode.Submodule);
      expect(GitFileMode.canonicalize(GitFileMode.Dir), GitFileMode.Dir);
    });
  });

  test('writeTree canonicalizes malformed index modes', () async {
    var tmpDir = (await Directory.systemTemp.createTemp('_git_')).path;
    GitRepository.init(tmpDir);
    var repo = GitRepository.load(tmpDir);

    var blob = GitBlob(utf8.encode('hello'), null);
    repo.objStorage.writeObject(blob);

    var now = DateTime.now();
    var index = GitIndex(versionNo: 2);
    index.entries = [
      GitIndexEntry(
        cTime: now,
        mTime: now,
        dev: 0,
        ino: 0,
        mode: GitFileMode.parse('100600'), // 0600 file -> must become 100644
        uid: 0,
        gid: 0,
        fileSize: 5,
        hash: blob.hash,
        path: 'note.md',
      ),
      GitIndexEntry(
        cTime: now,
        mTime: now,
        dev: 0,
        ino: 0,
        mode: GitFileMode.parse('100755'), // executable -> stays 100755
        uid: 0,
        gid: 0,
        fileSize: 5,
        hash: blob.hash,
        path: 'run.sh',
      ),
    ];

    var treeHash = repo.writeTree(index);
    var tree = repo.objStorage.readTree(treeHash);
    var modes = {for (var e in tree.entries) e.name: e.mode};

    expect(modes['note.md'], GitFileMode.Regular);
    expect(modes['run.sh'], GitFileMode.Executable);

    repo.close();
  });
}
