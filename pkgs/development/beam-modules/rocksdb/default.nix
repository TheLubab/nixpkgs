{
  lib,
  buildRebar3,
  fetchFromGitHub,
  cmake,
  nix-update-script,

  # rename to avoid recursion since this module share same name
  rocksdb-lib,

  croaring,
  openssl,
  snappy,
  lz4,
  bzip2,
  zlib,
  zstd,
  tbb,

  withSnappy ? true,
  withLz4 ? true,
  withBzip2 ? true,
  withZlib ? true,
  withZstd ? true,
  withTbb ? false,
}:

let
  version = "3.1.2";
in
buildRebar3 {
  name = "rocksdb";
  inherit version;

  src = fetchFromGitHub {
    owner = "EnkiMultimedia";
    repo = "erlang-rocksdb";
    tag = version;
    hash = "sha256-TQhi7eNiRvPxtXf8e4cGr1L1maP+ZgDWyqS8YKZcmeA=";
  };

  beamDeps = [ ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    rocksdb-lib
    croaring
    openssl
  ]
  ++ lib.optional withSnappy snappy
  ++ lib.optional withLz4 lz4
  ++ lib.optional withBzip2 bzip2
  ++ lib.optional withZlib zlib
  ++ lib.optional withZstd zstd
  ++ lib.optional withTbb tbb;

  # rebar drives cmake itself
  dontUseCmakeConfigure = true;

  postPatch = ''
    substituteInPlace c_src/CMakeLists.txt \
      --replace-fail "find_package(zlib" "find_package(ZLIB" \
      --replace-fail "include(build-croaring)" "find_path(CROARING_INCLUDE_DIR roaring/roaring.h REQUIRED)
      find_library(CROARING_LIBRARY roaring REQUIRED)"
  '';

  env = {
    ERLANG_ROCKSDB_OPTS = lib.concatStringsSep " " [
      (lib.cmakeBool "WITH_SYSTEM_ROCKSDB" true)
      (lib.cmakeBool "WITH_SNAPPY" withSnappy)
      (lib.cmakeBool "WITH_LZ4" withLz4)
      (lib.cmakeBool "WITH_BZ2" withBzip2)
      (lib.cmakeBool "WITH_ZLIB" withZlib)
      (lib.cmakeBool "WITH_ZSTD" withZstd)
      (lib.cmakeBool "WITH_TBB" withTbb)
      # never fall back to bundled copies
      (lib.cmakeBool "WITH_BUNDLE_ZSTD" false)
      (lib.cmakeBool "WITH_BUNDLE_SNAPPY" false)
      (lib.cmakeBool "WITH_BUNDLE_LZ4" false)
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    ];
  };

  preBuild = ''
    export ERLANG_ROCKSDB_BUILDOPTS="-j$NIX_BUILD_CORES"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/EnkiMultimedia/erlang-rocksdb";
    changelog = "https://github.com/EnkiMultimedia/erlang-rocksdb/releases/tag/${version}";
    description = "Erlang wrapper for RocksDB with selectable compression codecs";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = [ lib.maintainers.yourhandle ];
    teams = [ lib.teams.beam ];
  };
}
