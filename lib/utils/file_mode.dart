import 'package:equatable/equatable.dart';

class GitFileMode extends Equatable {
  final int val;

  GitFileMode(this.val) {
    if (val <= 0) {
      throw Exception('Invalid FileMode: $val');
    }
  }

  static GitFileMode parse(String str) {
    var val = int.parse(str, radix: 8);
    if (val <= 0) {
      throw Exception('Invalid FileMode: $str');
    }
    return GitFileMode(val);
  }

  static final Dir = GitFileMode(int.parse('40000', radix: 8));
  static final Regular = GitFileMode(int.parse('100644', radix: 8));
  static final Deprecated = GitFileMode(int.parse('100664', radix: 8));
  static final Executable = GitFileMode(int.parse('100755', radix: 8));
  static final Symlink = GitFileMode(int.parse('120000', radix: 8));
  static final Submodule = GitFileMode(int.parse('160000', radix: 8));

  /// Normalizes a mode to the canonical git representation.
  ///
  /// git only stores the executable bit for regular blobs; filesystem
  /// permission bits must not leak into tree objects (a 0600 file must not be
  /// written as 0100600, which go-git rejects as a malformed mode).
  /// Symlinks, submodules and directories pass through unchanged.
  static GitFileMode canonicalize(GitFileMode mode) {
    if (mode == Symlink || mode == Submodule || mode == Dir) {
      return mode;
    }
    final typeMask = int.parse('170000', radix: 8);
    final regularFile = int.parse('100000', radix: 8);
    final execBits = int.parse('111', radix: 8);
    final typeBits = mode.val & typeMask;
    if (typeBits == regularFile) {
      // Regular file: keep only the executable bit.
      return (mode.val & execBits) != 0 ? Executable : Regular;
    }
    return mode;
  }

  @override
  List<Object> get props => [val];

  @override
  String toString() {
    return val.toRadixString(8);
  }

  bool get isZero => val == 0;

  // FIXME: Is this written in little endian in bytes?
}
