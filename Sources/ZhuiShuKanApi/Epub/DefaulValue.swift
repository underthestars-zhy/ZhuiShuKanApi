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
    <dc:title>$(title)</dc:title>
    <dc:identifier id="ePub-UUID">urn:uuid:$(uuid)</dc:identifier>
    <dc:creator id="creator"></dc:creator>
    <meta refines="#creator" property="role" scheme="marc:relators">aut</meta>
    <dc:language>en</dc:language>
    <dc:date>$(date)</dc:date>
    <meta property="dcterms:modified">2022-08-21T11:32:35Z</meta>
    <dc:contributor id="contributor">Ryan Zhu</dc:contributor>
    <meta refines="#contributor" property="role" scheme="marc:relators">bkp</meta>
  </metadata>

  <manifest>
      <!-- Navigation -->
      <item id="nav" href="navigation.xhtml" properties="nav" media-type="application/xhtml+xml" />
      <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />

      <!-- HTML files -->
      $(html)

      <!-- CSS files -->

      <!-- Images -->

      <!-- Videos -->
  </manifest>

  <spine toc="ncx">
    <itemref idref="chapter-1" />
    <itemref idref="chapter-2" />
    <itemref idref="chapter-3" />
  </spine>
</package>
"""
let toc = """
<ncx version="2005-1" xml:lang="en" xmlns="http://www.daisy.org/z3986/2005/ncx/">
    <head>
        <meta name="dtb:uid" content="urn:uuid:$(title)"/>
        <meta name="dtb:depth" content="1"/>
        <meta name="dtb:totalPageCount" content="0"/>
        <meta name="dtb:maxPageNumber" content="0"/>
    </head>

    <docTitle>
        <text>$(title)</text>
    </docTitle>

    <docAuthor>
        <text></text>
    </docAuthor>

    <navMap>
        $(navPoint)
    </navMap>
</ncx>
"""
