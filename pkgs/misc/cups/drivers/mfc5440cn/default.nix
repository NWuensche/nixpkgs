{ pkgs, stdenv, fetchurl, cups, dpkg, ghostscript, patchelf, a2ps, coreutils, gnused, gawk, file, makeWrapper, tcsh }:

stdenv.mkDerivation rec {
  name = "mfc5400cn-${version}";
  version = "3.0.0-1";

  src = fetchurl {
    url = "http://download.brother.com/welcome/dlf006148/mfc5440cnlpr-1.0.2-1.i386.deb";
    sha256 = "ce1c2f3778e4101ddd114d5a6274a8b5a034807f54d68e1b74de42007a616db6";
  };

  srcLPD = ./brlpdwrapperMFC5440CN;
  srcPPD = ./MFC.ppd;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ cups ghostscript dpkg a2ps tcsh ];

  unpackPhase = "true";

  installPhase = ''
    ar x $src
    tar xzvf data.tar.gz
    substituteInPlace usr/local/Brother/lpd/filterMFC5440CN \
      --replace /opt "$out/opt"
    sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' usr/local/Brother/lpd/psconvertij2

    patchelf --set-interpreter ${stdenv.glibc.out}/lib/ld-linux.so.2 usr/local/Brother/lpd/rastertobrij2
    patchelf --set-interpreter ${stdenv.glibc}/lib/ld-linux.so.2 usr/bin/brprintconfij2

    ln -sr usr/lib/libbrcompij2.so.1.0.2 -T usr/lib/libbrcompij2.so.1
    patchelf --set-rpath $out/usr/lib usr/local/Brother/lpd/rastertobrij2

    #install -m 755 $srcLPD $out/lib/cups/filter/brlpdwrapperMFC5440CN
    cp $srcLPD ./brlpdwrapperMFC5440CN
    patchShebangs ./brlpdwrapperMFC5440CN
    substituteInPlace brlpdwrapperMFC5440CN \
      --replace /usr "$out/usr" \
      --replace CHANGE "$out/share/cups/model/brmfc5440cn_cups.ppd"
    #      --replace brprintconfij2 "$out/usr/bin/brprintconfij2"
    substituteInPlace usr/local/Brother/lpd/filterMFC5440CN \
      --replace /usr/local/Brother/ "$out/usr/local/Brother/"

    mkdir -p $out
    mkdir -p $out/lib/cups/filter/
    mkdir -p $out/share/cups/model
    cp -r -v usr $out
    cp brlpdwrapperMFC5440CN $out/lib/cups/filter/brlpdwrapperMFC5440CN
    cp $srcPPD $out/share/cups/model/brmfc5440cn_cups.ppd

    wrapProgram  $out/lib/cups/filter/brlpdwrapperMFC5440CN \
     --prefix PATH ":" "$out/usr/bin:${stdenv.lib.makeBinPath [ coreutils ]}"
    wrapProgram $out/usr/local/Brother/lpd/psconvertij2 \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ gnused coreutils gawk ] }
    wrapProgram $out/usr/local/Brother/lpd/filterMFC5440CN \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }
    '';

      postInstall = ''
    chmod 0777 $out/lib/cups/filter/brlpdwrapperMFC5440CN
      '';

  meta = {
    homepage = http://www.brother.com/;
    description = "Brother MFC-5440CN driver";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = http://support.brother.com/g/b/downloadtop.aspx?c=de&lang=de&prod=mfc5440cn_all;
    maintainers = [ stdenv.lib.maintainers.nwuensche ];
  };
}
