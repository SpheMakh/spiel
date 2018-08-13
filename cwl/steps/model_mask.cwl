cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: gijzelaerr/spiel
                                                       



baseCommand: python

arguments:
  - prefix: -c
    valueFrom: |
      from astLib.astWCS import WCS
      import astropy.io.fits as fitsio
      from skimage.draw import ellipse
      import numpy
      import Tigger
      
      true = True
      false = False
      
      model = Tigger.load("$(inputs.skymodel.path)")
      image = "$(inputs.fits_template.path)"
      with fitsio.open(image) as hdu:
        data = hdu[0].data[0,0,...]
        hdr = hdu[0].header    
      
      wcs = WCS(image)
      cell = abs(hdr["CDELT1"])
      bmaj = hdr["BMAJ"]
      bmin = hdr["BMIN"]
      bpa = hdr["BPA"]
      npix = hdr["NAXIS1"]
      
      mask = numpy.zeros([npix, npix], dtype=numpy.float32)
      for src in model.sources:
        ra = numpy.rad2deg(src.pos.ra)
        dec = numpy.rad2deg(src.pos.dec)
        if src.shape:
          emaj = numpy.rad2deg(src.shape.ex)
          emin = numpy.rad2deg(src.shape.ey)
          emin = int(emin/cell)
          emaj = int(emaj/cell)
        else:
          emaj = int(bmaj/cell)
          emin = int(bmin/cell)
            
        raPix,decPix = wcs.wcs2pix(ra, dec)
        # check if source is inside image
        if ( raPix < 0 or decPix < 0) or ( raPix > npix or decPix > npix):
            continue
        aa, bb = ellipse(decPix, raPix, emaj, emin, mask.shape)
        mask[aa,bb] = 1

      fitsio.writeto("$(inputs.maskname)", mask[numpy.newaxis,numpy.newaxis,...], hdr)

inputs:
  skymodel:
    type: File

  fits_template:
    type: File
  
  maskname:
    type: string?
    default: image-mask.fits

outputs:
  mask:
    type: File
    outputBinding:
      glob: $(inputs.maskname)
