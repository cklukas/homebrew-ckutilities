class CkUtilities < Formula
  desc "ckVision-native terminal utility suite"
  homepage "https://github.com/cklukas/ckUtilities"
  url "https://github.com/cklukas/ckUtilities/archive/refs/tags/v0.1.1.tar.gz"
  version "0.1.1"
  sha256 "1d08414c4c383f209a4c59bbd407605c3f7f5ce6c545bea4dc4e9c32ae6eae99"
  license "GPL-3.0-or-later"

  resource "ckvision" do
    url "https://github.com/cklukas/ckVision/archive/338d950e7473c5fdd4f88ea6b37d9f842543ac15.tar.gz"
    sha256 "fcded487cff6c55782c1723df659cef16abb8c1fcd0b4a95366a6b554f07fc6d"
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
    system "cmake", "--install", "build"
  end

  test do
    %w[ck-utilities ck-json-view ck-find ck-du ck-config ck-edit ck-chat].each do |tool|
      assert_match "Usage:", shell_output("#{bin}/#{tool} --help")
    end
  end
end
