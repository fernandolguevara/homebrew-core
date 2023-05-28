class V2ray < Formula
  desc "Platform for building proxies to bypass network restrictions"
  homepage "https://v2fly.org/"
  url "https://github.com/v2fly/v2ray-core/archive/v5.5.0.tar.gz"
  sha256 "b9110ff10d87b245efd42b5a93beb4a3e5138fcfe92d09cadfb6a72cc4e1c91c"
  license all_of: ["MIT", "CC-BY-SA-4.0"]
  head "https://github.com/v2fly/v2ray-core.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "42b656d044d5a887a56c44cd4571a6f1e88123772faf44b8228a00b3f8a98411"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "42b656d044d5a887a56c44cd4571a6f1e88123772faf44b8228a00b3f8a98411"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "42b656d044d5a887a56c44cd4571a6f1e88123772faf44b8228a00b3f8a98411"
    sha256 cellar: :any_skip_relocation, ventura:        "64716145382e749dfbe9018efa5fcd2f5ab598edfd6ced0083beeb8ddf3811a6"
    sha256 cellar: :any_skip_relocation, monterey:       "64716145382e749dfbe9018efa5fcd2f5ab598edfd6ced0083beeb8ddf3811a6"
    sha256 cellar: :any_skip_relocation, big_sur:        "64716145382e749dfbe9018efa5fcd2f5ab598edfd6ced0083beeb8ddf3811a6"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "53f012833d85b0a2a48b40064a85210324b36da910169286cedd87a2f6cab999"
  end

  depends_on "go" => :build

  resource "geoip" do
    url "https://github.com/v2fly/geoip/releases/download/202305250042/geoip.dat"
    sha256 "c9ff6547c0715645414af758a961cd8a305016df6fe9656b836f7b3ad648a568"
  end

  resource "geoip-only-cn-private" do
    url "https://github.com/v2fly/geoip/releases/download/202305250042/geoip-only-cn-private.dat"
    sha256 "f776c699a86fd8d775c1dc4d2e7bc04b2d9a80e11a5d5a73c962fda955d96162"
  end

  resource "geosite" do
    url "https://github.com/v2fly/domain-list-community/releases/download/20230525170625/dlc.dat"
    sha256 "c65889ccabaccbea21fa8c9bed6e896be53be321e7a3a841f33c170821b7f1af"
  end

  def install
    ldflags = "-s -w -buildid="
    system "go", "build", *std_go_args(ldflags: ldflags, output: libexec/"v2ray"), "./main"

    (bin/"v2ray").write_env_script libexec/"v2ray",
      V2RAY_LOCATION_ASSET: "${V2RAY_LOCATION_ASSET:-#{pkgshare}}"

    pkgetc.install "release/config/config.json"

    resource("geoip").stage do
      pkgshare.install "geoip.dat"
    end

    resource("geoip-only-cn-private").stage do
      pkgshare.install "geoip-only-cn-private.dat"
    end

    resource("geosite").stage do
      pkgshare.install "dlc.dat" => "geosite.dat"
    end
  end

  service do
    run [opt_bin/"v2ray", "run", "-config", etc/"v2ray/config.json"]
    keep_alive true
  end

  test do
    (testpath/"config.json").write <<~EOS
      {
        "log": {
          "access": "#{testpath}/log"
        },
        "outbounds": [
          {
            "protocol": "freedom",
            "tag": "direct"
          }
        ],
        "routing": {
          "rules": [
            {
              "ip": [
                "geoip:private"
              ],
              "outboundTag": "direct",
              "type": "field"
            },
            {
              "domains": [
                "geosite:private"
              ],
              "outboundTag": "direct",
              "type": "field"
            }
          ]
        }
      }
    EOS
    output = shell_output "#{bin}/v2ray test -c #{testpath}/config.json"

    assert_match "Configuration OK", output
    assert_predicate testpath/"log", :exist?
  end
end
