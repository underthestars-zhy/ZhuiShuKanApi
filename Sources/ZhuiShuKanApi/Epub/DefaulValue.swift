//
//  File.swift
//  
//
//  Created by 朱浩宇 on 2022/8/21.
//

import Foundation

let minetype = "application/epub+zip"
let container = """
<?xml version="1.0" encoding="UTF-8" ?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OPS/book.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"""
let bookOpf = """
<?xml version="1.0"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="ePub-UUID">

  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>$(book-name)</dc:title>
    <dc:identifier id="ePub-UUID">urn:uuid:$(uuid)</dc:identifier>
    <dc:creator id="creator"></dc:creator>
    <meta refines="#creator" property="role" scheme="marc:relators">aut</meta>
    <dc:language>en</dc:language>
    <dc:date>2022-08-21</dc:date>
    <meta property="dcterms:modified">2022-08-21T11:32:35Z</meta>
    <dc:contributor id="contributor">Ryan Zhu</dc:contributor>
    <meta refines="#contributor" property="role" scheme="marc:relators">bkp</meta>
    <meta name="cover" content="coverImage" />
  </metadata>

  <manifest>
      <!-- Navigation -->
      <item id="nav" href="navigation.xhtml" properties="nav" media-type="application/xhtml+xml" />
      <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />

      <!-- HTML files -->
      $(html)

      <!-- CSS files -->

      <!-- Images -->
      <item id="coverImage" href="cover.png" media-type="image/png" />

      <!-- Videos -->
  </manifest>

  <spine toc="ncx">
    $(ncx)
  </spine>
    <guide>
        <reference href="cover.xhtml" type="cover" title="Cover" />
    </guide>
</package>
"""
let toc = """
<ncx version="2005-1" xml:lang="en" xmlns="http://www.daisy.org/z3986/2005/ncx/">
    <head>
        <meta name="dtb:uid" content="urn:uuid:$(uuid)"/>
        <meta name="dtb:depth" content="1"/>
        <meta name="dtb:totalPageCount" content="0"/>
        <meta name="dtb:maxPageNumber" content="0"/>
    </head>

    <docTitle>
        <text>$(book-name)</text>
    </docTitle>

    <docAuthor>
        <text></text>
    </docAuthor>

    <navMap>
        $(navPoint)
    </navMap>
</ncx>
"""
let xhtml = """
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
    <meta charset="utf-8" />
    <title>$(chapter-title)</title>
</head>
<body>
    <section epub:type="chapter" class="chapter">
    <h1 class="chapter-title" id="chapter-$(id)">$(chapter-title)</h1>
    $(content)
    </section>
</body>
</html>
"""
let navigationXhtml = """
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
    <head>
        <title>$(book-name)</title>
    </head>
    <body>
        <nav id="toc" epub:type="toc">
            <ol>
                $(content)
            </ol>
        </nav>
    </body>
</html>
"""
let cover = """
<?xml version="1.0" encoding="UTF-8"?><html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
    <head>
        <meta charset="utf-8" />
        <title>Cover</title>
          <link rel="stylesheet" href="css/style.css" type="text/css" />
    </head>
    <body>
        <div class="cover">
        <img src="cover.png" alt="$(book-name)" class="cover" />
        </div>
    </body>
</html>
"""
