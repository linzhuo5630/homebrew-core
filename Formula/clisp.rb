class Clisp < Formula
  desc "GNU CLISP, a Common Lisp implementation"
  homepage "http://www.clisp.org/"
  url "https://ftpmirror.gnu.org/clisp/release/2.49/clisp-2.49.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/clisp/release/2.49/clisp-2.49.tar.bz2"
  sha256 "8132ff353afaa70e6b19367a25ae3d5a43627279c25647c220641fed00f8e890"

  bottle do
    rebuild 1
    sha256 "95f69318c63bcd1e6dc7be27441d5250b647b0362f84de224cade9fc017de3d9" => :sierra
    sha256 "30772a480313ed0f2a196002f35f53a48ffc7d6697139320a7b166f4e7c5b18a" => :el_capitan
    sha256 "a2c177ee30d6748c6d5d0bf395ed7f9bd248d7da2291eabe2f3a72179ba52a75" => :yosemite
  end

  depends_on "libsigsegv"
  depends_on "readline"

  fails_with :llvm do
    build 2334
    cause "Configure fails on XCode 4/Snow Leopard."
  end

  patch :DATA

  patch :p0 do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/e2cc7c1/clisp/patch-src_lispbibl_d.diff"
    sha256 "fd4e8a0327e04c224fb14ad6094741034d14cb45da5b56a2f3e7c930f84fd9a0"
  end

  def install
    ENV.deparallelize # This build isn't parallel safe.
    ENV.O0 # Any optimization breaks the build

    # Clisp requires to select word size explicitly this way,
    # set it in CFLAGS won't work.
    ENV["CC"] = "#{ENV.cc} -m#{MacOS.prefer_64_bit? ? 64 : 32}"

    # Work around "configure: error: unrecognized option: `--elispdir"
    # Upstream issue 16 Aug 2016 https://sourceforge.net/p/clisp/bugs/680/
    inreplace "src/makemake.in", "${datarootdir}/emacs/site-lisp", elisp

    system "./configure", "--prefix=#{prefix}",
                          "--with-readline=yes"

    cd "src" do
      # Multiple -O options will be in the generated Makefile,
      # make Homebrew's the last such option so it's effective.
      inreplace "Makefile" do |s|
        s.change_make_var! "CFLAGS", "#{s.get_make_var("CFLAGS")} #{ENV["CFLAGS"]}"
      end

      # The ulimit must be set, otherwise `make` will fail and tell you to do so
      system "ulimit -s 16384 && make"

      if MacOS.version >= :lion
        opoo <<-EOS.undent
           `make check` fails so we are skipping it.
           However, there will likely be other issues present.
           Please take them upstream to the clisp project itself.
        EOS
      else
        # Considering the complexity of this package, a self-check is highly recommended.
        system "make", "check"
      end

      system "make", "install"
    end
  end

  test do
    system "#{bin}/clisp", "--version"
  end
end

__END__
diff --git a/src/stream.d b/src/stream.d
index 5345ed6..cf14e29 100644
--- a/src/stream.d
+++ b/src/stream.d
@@ -3994,7 +3994,7 @@ global object iconv_range (object encoding, uintL start, uintL end, uintL maxint
 nonreturning_function(extern, error_unencodable, (object encoding, chart ch));
 
 /* Avoid annoying warning caused by a wrongly standardized iconv() prototype. */
-#ifdef GNU_LIBICONV
+#if defined(GNU_LIBICONV) && !defined(__APPLE_CC__)
   #undef iconv
   #define iconv(cd,inbuf,inbytesleft,outbuf,outbytesleft) \
     libiconv(cd,(ICONV_CONST char **)(inbuf),inbytesleft,outbuf,outbytesleft)
