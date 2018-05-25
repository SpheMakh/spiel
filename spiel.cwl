cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement


inputs:
 random_seed: int
 telescope: string
 synthesis: float
 dtime: float
 freq0: float
 dfreq: float
 nchan: int
 config: File
 ra: float
 dec: float
 mgain: float
 niter: int
 scale: string
 size_x: int
 size_y: int
 fov: float
 pb_fwhm: float
 nsrc: int
 column: string
 weight: string
 randomise_pos: boolean
 sefd: float
 auto_mask: float
 auto_threshold: float

outputs:
  dirty:
    type: File
    outputSource: rename_dirty/renamed
  cleaned:
    type: File
    outputSource: rename_cleaned/renamed
  residual:
    type: File
    outputSource: rename_residual/renamed
  model:
    type: File
    outputSource: rename_model/renamed
  skymodel:
    type: File
    outputSource: rename_skymodel/renamed
  fitsmodel:
    type: File
    outputSource: rename_fitsmodel/renamed
  psf:
    type: File
    outputSource: rename_psf/renamed
  simulated_vis:
    type: Directory
    outputSource: simulator/ms_out
    

steps:
  randomize:
    run: steps/randomize.cwl
    in:
       random_seed: random_seed
    out:
       [dec, flux_scale, nsrc]

  simms:
    run: steps/simms.cwl
    in:
      telescope: telescope
      ra: ra
      dec: randomize/dec
      synthesis: synthesis
      dtime: dtime
      freq0: freq0
      dfreq: dfreq
      nchan: nchan
    out:
      [ms]

  make_skymodel:
    run: steps/skymodel.cwl
    in:
      ra: ra
      dec: randomize/dec
      seed: random_seed
      freq0: freq0
      fov: fov
      flux_scale: randomize/flux_scale
      nsrc: randomize/nsrc
      pb_fwhm: pb_fwhm
      nsrc: nsrc

    out:
      [skymodel]


  simulator:
    run: steps/simulator.cwl
    in:
      ms: simms/ms
      config: config
      output_column: column
      skymodel: make_skymodel/skymodel
      sefd: sefd
      flux_scale: randomize/flux_scale
      dtime: dtime
      dfreq: dfreq

    out:
      [ms_out]

  wsclean:
    run: steps/wsclean.cwl
    in:
      size_x: size_x
      size_y: size_y
      scale: scale
      niter: niter
      mgain: mgain
      column: column
      weight: weight
      ms: simulator/ms_out
      make-psf:
        valueFrom: $(true)
      auto_mask: auto_mask
      auto_threshold: auto_threshold
    out:
      [cleaned, dirty, residual, model, psf]

  tigger_restore:
    run: steps/tigger_restore.cwl
    in:
      image: wsclean/dirty
      skymodel: make_skymodel/skymodel
    out:
      [fitsmodel]

  rename_skymodel:
    run: steps/rename.cwl
    in:
      file: make_skymodel/skymodel
      prefix: random_seed
    out:
      - renamed

  rename_cleaned:
    run: steps/rename.cwl
    in:
      file: wsclean/cleaned
      prefix: random_seed
    out:
      - renamed

  rename_dirty:
    run: steps/rename.cwl
    in:
      file: wsclean/dirty
      prefix: random_seed
    out:
      - renamed

  rename_residual:
    run: steps/rename.cwl
    in:
      file: wsclean/residual
      prefix: random_seed
    out:
      - renamed

  rename_model:
    run: steps/rename.cwl
    in:
      file: wsclean/model
      prefix: random_seed
    out:
      - renamed

  rename_fitsmodel:
    run: steps/rename.cwl
    in:
      file: tigger_restore/fitsmodel
      prefix: random_seed
    out:
      - renamed


  rename_psf:
    run: steps/rename.cwl
    in:
      file: wsclean/psf
      prefix: random_seed
    out:
      - renamed
