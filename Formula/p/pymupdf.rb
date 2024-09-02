class Pymupdf < Formula
  desc "Python bindings for the PDF toolkit and renderer MuPDF"
  homepage "https://pymupdf.readthedocs.io/en/latest/"
  url "https://files.pythonhosted.org/packages/83/57/da06ca4886afc71a624e4b463d05f45c8a822596ede939957295e229eb4e/PyMuPDF-1.24.10.tar.gz"
  sha256 "bd3ebd6d3fb8a845582098362f885bfb0a31ae4272587efc2c55c5e29fe7327a"
  license "AGPL-3.0-only"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "f543b5454110f9b2f181ca8e11e27eccc81dc0b1f11adb8ad848fdaf45e44ea5"
    sha256 cellar: :any,                 arm64_ventura:  "f9a1c7dcf13f13e9f6e093407aa698cbe42be881e14be295babb0e8491ebb569"
    sha256 cellar: :any,                 arm64_monterey: "2dbe9279e862867b39c5ba0032b077d220ec1b71846b8a5f252cfbcf3de15c8f"
    sha256 cellar: :any,                 sonoma:         "33e0783b39c9bf13547bd329bcc49ad2795ae05df8b64a90c9a578799fd6a8da"
    sha256 cellar: :any,                 ventura:        "1147a501badc1f10b75b14da7300f544732fb1ad39aa4b1f00d52b73d62dac19"
    sha256 cellar: :any,                 monterey:       "f2ed85726735323c5e17f04ede5753ffdaad84af1662ca5a1fe8de00ff2f586a"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "211a5272d9d51c8f35c998321cc83cf427e4c1fbc10ff994972ebeedd8557c02"
  end

  depends_on "freetype" => :build
  depends_on "python-setuptools" => :build
  depends_on "swig" => :build
  depends_on "mupdf"
  depends_on "python@3.12"

  def python3
    "python3.12"
  end

  resource "pymupdfb" do
    url "https://files.pythonhosted.org/packages/c9/ff/ecfcb41414b51976974d74c8e35fef0a0e5b47c7046a11c860553f5dccf0/PyMuPDFb-1.24.10.tar.gz"
    sha256 "007b91fa9b528c5c0eecea2e49c486ac02e878274f9e31522bdd948adc5f8327"
  end

  def install
    # Makes setup skip build stage for mupdf
    # https://github.com/pymupdf/PyMuPDF/blob/1.20.0/setup.py#L447
    ENV["PYMUPDF_SETUP_MUPDF_BUILD"] = ""
    # Builds only classic implementation
    # https://github.com/pymupdf/PyMuPDF/issues/2628
    ENV["PYMUPDF_SETUP_IMPLEMENTATIONS"] = "a"
    ENV["PYMUPDF_INCLUDES"] = "#{Formula["mupdf"].opt_include}:#{Formula["freetype"].opt_include}/freetype2"
    ENV["PYMUPDF_MUPDF_LIB"] = Formula["mupdf"].opt_lib.to_s

    system python3, "-m", "pip", "install", *std_pip_args, "."
  end

  test do
    (testpath/"test.py").write <<~EOS
      import sys
      from pathlib import Path

      # per 1.23.9 release, `fitz` module got renamed to `fitz_old`
      import fitz_old as fitz

      in_pdf = sys.argv[1]
      out_png = sys.argv[2]

      # Convert first page to PNG
      pdf_doc = fitz.open(in_pdf)
      pdf_page = pdf_doc.load_page(0)
      png_bytes = pdf_page.get_pixmap().tobytes()

      Path(out_png).write_bytes(png_bytes)
    EOS

    in_pdf = test_fixtures("test.pdf")
    out_png = testpath/"test.png"

    system python3, testpath/"test.py", in_pdf, out_png
    assert_predicate out_png, :exist?
  end
end
