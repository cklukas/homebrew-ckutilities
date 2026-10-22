class CkUtilities < Formula
  desc "ckVision-native terminal utility suite"
  homepage "https://github.com/cklukas/ckUtilities"
  url "https://github.com/cklukas/ckUtilities/archive/refs/tags/v0.2.0.tar.gz"
  version "0.2.0"
  sha256 "c37ea42ddcdf24d5cff7e6f7fde88fbbae18e8bf7830f5d4114fb9ff9a8daba2"
  license "GPL-3.0-or-later"

  resource "ckvision" do
    url "https://github.com/cklukas/ckVision/archive/57b379d0dddd6a3b517b614a4eb2d1a1c99b474b.tar.gz"
    sha256 "f9d54bc52541919c6d5700d32801432e0b258dc3c49f99a1b458caf952509508"
  end

  resource "llama_cpp" do
    url "https://github.com/ggerganov/llama.cpp/archive/0124ac989f7e7bf08803788f66dbe4106bdcdd58.tar.gz"
    sha256 "8cbda24890f30e5f80c522948b116498345a9ecaf5926d2ed2a700f6bbc3c944"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "curl"
  depends_on "nlohmann-json"

  def install
    resource("ckvision").stage buildpath/"ckvision"
    ckvision_prefix = buildpath/"ckvision-sdk"
    system "cmake", "-S", "ckvision", "-B", "ckvision-build", "-G", "Ninja",
           "-DCMAKE_BUILD_TYPE=Release",
           "-DCKVISION_BUILD_EXAMPLES=OFF",
           "-DCKVISION_BUILD_TESTING=OFF",
           "-DCKVISION_BUILD_FUZZERS=OFF",
           "-DCMAKE_INSTALL_PREFIX=#{ckvision_prefix}"
    system "cmake", "--build", "ckvision-build", "--parallel"
    system "cmake", "--install", "ckvision-build"

    resource("llama_cpp").stage buildpath/"llama_cpp"
    llama_source = buildpath/"llama_cpp"
    unless (llama_source/"CMakeLists.txt").exist?
      llama_source = llama_source.children.find do |candidate|
        (candidate/"CMakeLists.txt").exist?
      end
    end
    odie "llama.cpp resource did not contain CMakeLists.txt" unless llama_source
    curl_prefix = Formula["curl"].opt_prefix
    json_prefix = Formula["nlohmann-json"].opt_prefix
    system "cmake", "-S", ".", "-B", "build", "-G", "Ninja",
       "-DCMAKE_BUILD_TYPE=Release",
       "-DBUILD_TESTING=OFF",
       "-DLLAMA_BUILD_TESTS=OFF",
       "-DLLAMA_BUILD_EXAMPLES=OFF",
       "-DCMAKE_PREFIX_PATH=#{ckvision_prefix};#{curl_prefix};#{json_prefix}",
       "-DCK_LLAMA_CPP_SOURCE_DIR=#{llama_source}",
           *std_cmake_args
    system "cmake", "--build", "build"
    # Only the product: the executables, documentation, license and
    # sample configuration. Development headers and libraries, ours and
    # the bundled llama.cpp's, would collide with Homebrew's own
    # nlohmann-json and llama.cpp when the keg is linked.
    system "cmake", "--install", "build", "--component", "Runtime"
  end

  test do
    %w[ck-utilities ck-json-view ck-find ck-du ck-config ck-edit ck-chat ck-todo ck-sysmon].each do |tool|
      assert_match "Usage:", shell_output("#{bin}/#{tool} --help")
    end
  end
end
